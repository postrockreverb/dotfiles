-- Thin wrapper over the git CLI.
--
-- Everything runs with `cwd = root`. Listing goes through for-each-ref: one
-- process returns every branch with its upstream state, against `git branch`
-- whose porcelain output was never meant to be parsed.

local m = {}

local function run(root, args)
  local cmd = { "git" }
  vim.list_extend(cmd, args)
  return vim.system(cmd, { cwd = root, text = true }):wait()
end

-- Reads go through this so a slow repo never blocks the main loop. `on_done`
-- is called off the main loop -- schedule anything that touches a buffer.
local function run_async(root, args, on_done)
  local cmd = { "git" }
  vim.list_extend(cmd, args)
  vim.system(cmd, { cwd = root, text = true }, on_done)
end

m.err = function(res)
  local out = vim.trim((res.stderr or "") .. (res.stdout or ""))
  return out ~= "" and out or ("git exited with " .. tostring(res.code))
end

m.root = function(dir)
  local res = vim.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true }):wait()
  if res.code ~= 0 then
    return nil, "not a git repository"
  end
  return vim.trim(res.stdout)
end

-- One entry per branch: { name, display, short, remote, current, upstream,
-- gone, ahead, behind }. `short` is what checkout wants -- for a remote
-- branch the name without the remote, which `git switch` turns into a local
-- tracking branch; `remote` is the part before it, and doubles as the kind:
-- entries with no `remote` are local branches.
local function parse_refs(res)
  if res.code ~= 0 then
    return nil, m.err(res)
  end

  local entries = {}
  for _, line in ipairs(vim.split(res.stdout or "", "\n", { plain = true })) do
    if line ~= "" then
      local head, ref, name, upstream, track, symref, sha = unpack(vim.split(line, "\0", { plain = true }))
      local is_remote = vim.startswith(ref, "refs/remotes/")
      -- Symbolic refs like origin/HEAD point at a branch already listed.
      if not (is_remote and symref ~= "") then
        local rem, short
        if is_remote then
          rem, short = name:match("^([^/]+)/(.+)$")
        end
        table.insert(entries, {
          name = name,
          display = name,
          short = short or name,
          remote = rem,
          sha = sha,
          current = head == "*",
          upstream = upstream ~= "" and upstream or nil,
          gone = track == "[gone]",
          ahead = tonumber(track:match("ahead (%d+)")) or 0,
          behind = tonumber(track:match("behind (%d+)")) or 0,
        })
      end
    end
  end
  return entries
end

-- Both namespaces in one process -- the views split the result, and column
-- widths come from the union so labels line up across them. Newest work
-- first, so the stale candidates for deletion collect at the bottom.
local function branches(root, on_done)
  local args = {
    "for-each-ref",
    "refs/heads",
    "refs/remotes",
    "--sort=-committerdate",
    "--format=%(HEAD)%00%(refname)%00%(refname:short)%00%(upstream:short)%00%(upstream:track)%00%(symref)%00%(objectname)",
  }
  run_async(root, args, function(res)
    on_done(parse_refs(res))
  end)
end

-- The ref [merged] is judged against: the default branch as origin knows it.
-- The remote-tracking ref is preferred over the local branch of the same
-- name, so work merged upstream is labelled even when the local default has
-- not pulled the merge yet. Nil when nothing resolves -- then nothing is
-- labelled merged.
local function merged_ref(root, on_done)
  run_async(root, { "symbolic-ref", "--short", "refs/remotes/origin/HEAD" }, function(res)
    if res.code == 0 then
      return on_done("refs/remotes/" .. vim.trim(res.stdout))
    end
    local candidates = {
      "refs/remotes/origin/main",
      "refs/heads/main",
      "refs/remotes/origin/master",
      "refs/heads/master",
    }
    local args = { "for-each-ref", "--format=%(refname)" }
    vim.list_extend(args, candidates)
    run_async(root, args, function(r)
      local have = {}
      for _, line in ipairs(vim.split(r.stdout or "", "\n", { plain = true })) do
        have[line] = true
      end
      for _, ref in ipairs(candidates) do
        if have[ref] then
          return on_done(ref)
        end
      end
      on_done(nil)
    end)
  end)
end

-- Names of branches whose tips are reachable from `ref`: safe to delete,
-- nothing on them is lost.
local function merged(root, ref, on_done)
  if not ref then
    return on_done({})
  end
  local args = {
    "for-each-ref",
    "refs/heads",
    "refs/remotes",
    "--merged=" .. ref,
    "--format=%(refname:short)",
  }
  run_async(root, args, function(res)
    local set = {}
    if res.code == 0 then
      for _, name in ipairs(vim.split(res.stdout or "", "\n", { plain = true })) do
        if name ~= "" then
          set[name] = true
        end
      end
    end
    on_done(set)
  end)
end

-- Where HEAD is when it sits on no branch: the remote branch at its tip when
-- there is one -- the usual result of checking a remote ref out detached --
-- otherwise the short sha. Nil when HEAD is on a branch, or unborn.
local function detached_at(root, on_done)
  run_async(root, { "rev-parse", "--verify", "--quiet", "--abbrev-ref", "HEAD" }, function(res)
    if res.code ~= 0 or vim.trim(res.stdout or "") ~= "HEAD" then
      return on_done(nil)
    end
    local args = { "for-each-ref", "refs/remotes", "--points-at", "HEAD", "--format=%(refname:short)%00%(symref)" }
    run_async(root, args, function(r)
      -- Skip symbolic refs: origin/HEAD points at the same commit and sorts
      -- before the branch actually being stood on.
      for _, line in ipairs(vim.split(r.stdout or "", "\n", { plain = true })) do
        local name, symref = unpack(vim.split(line, "\0", { plain = true }))
        if name and name ~= "" and (symref or "") == "" then
          return on_done(name)
        end
      end
      run_async(root, { "rev-parse", "--short", "HEAD" }, function(sha)
        on_done(vim.trim(sha.stdout or "?"))
      end)
    end)
  end)
end

-- The remote view's answer to the local `*`: mark the remote row HEAD
-- actually sits on -- the upstream of the current branch, or wherever HEAD
-- is detached -- but only when HEAD is at that remote tip. A local branch
-- that has drifted from its upstream leaves the remote row unmarked, and
-- checking it out brings you to the remote tip.
local function mark_position(root, entries, on_done)
  run_async(root, { "rev-parse", "HEAD", "--abbrev-ref", "HEAD" }, function(res)
    if res.code ~= 0 then
      return on_done()
    end
    local sha, ref = unpack(vim.split(vim.trim(res.stdout or ""), "\n", { plain = true }))

    local mark = function(name)
      for _, entry in ipairs(entries) do
        if entry.sha == sha and (name == nil or entry.name == name) then
          entry.current = true
          return
        end
      end
    end

    if ref == "HEAD" then
      -- Detached: the newest remote ref at HEAD's commit.
      mark(nil)
      return on_done()
    end
    run_async(root, { "rev-parse", "--abbrev-ref", ref .. "@{upstream}" }, function(up)
      if up.code == 0 then
        mark(vim.trim(up.stdout))
      end
      on_done()
    end)
  end)
end

-- Everything one refresh needs, gathered off the main loop: the branches of
-- one view, which of them are merged, and -- in the local view, when HEAD is
-- on no branch -- a synthetic first entry saying where it actually is, the
-- same line `git branch` prints. Calls `on_done(result, err)` exactly once,
-- off the main loop.
m.snapshot = function(root, remote, on_done)
  branches(root, function(all, err)
    if not all then
      return on_done(nil, err)
    end
    merged_ref(root, function(ref)
      merged(root, ref, function(set)
        local entries = vim.tbl_filter(function(entry)
          return (entry.remote ~= nil) == remote --
        end, all)
        local result = { entries = entries, all = all, merged = set }

        if remote then
          return mark_position(root, entries, function() on_done(result) end)
        end

        local on_branch = false
        for _, entry in ipairs(entries) do
          on_branch = on_branch or entry.current
        end
        if on_branch then
          return on_done(result)
        end

        detached_at(root, function(at)
          if at then
            -- `name` is HEAD so the preview logs from it. Deliberately not
            -- into `all`: that union sizes the label columns for both views,
            -- and this row exists only in this one -- counting it would push
            -- the local labels right of the remote ones. It carries no labels
            -- of its own, so its width is nobody's business but its row's.
            local head = {
              name = "HEAD",
              display = "(detached at " .. at .. ")",
              short = "HEAD",
              detached = true,
              current = true,
              ahead = 0,
              behind = 0,
            }
            table.insert(entries, 1, head)
          end
          on_done(result)
        end)
      end)
    end)
  end)
end

-- `switch` rather than `checkout`: given a short name with no local branch it
-- creates one tracking the remote, which is exactly what <CR> on a remote row
-- should do.
m.checkout = function(root, short)
  return run(root, { "switch", short })
end

m.checkout_detach = function(root, name)
  return run(root, { "switch", "--detach", name })
end

-- Whether the local branch `short` sits exactly at the tip of the remote ref
-- `name`. Nil when there is no local branch -- then a plain switch creates
-- one at the remote tip anyway.
m.local_tip_matches = function(root, short, name)
  local l = run(root, { "rev-parse", "--verify", "--quiet", "refs/heads/" .. short })
  if l.code ~= 0 then
    return nil
  end
  local r = run(root, { "rev-parse", "--verify", "--quiet", "refs/remotes/" .. name })
  return r.code == 0 and vim.trim(l.stdout) == vim.trim(r.stdout)
end

m.delete_local = function(root, name, force)
  return run(root, { "branch", force and "-D" or "-d", name })
end

-- A network round trip, so async: the caller notifies when it lands.
m.delete_remote = function(root, remote, branch, on_done)
  run_async(root, { "push", remote, "--delete", branch }, on_done)
end

-- The one verb that goes to the network for new data. Everything else reads
-- what is already on disk, so [gone] and the ahead/behind counts are only ever
-- as fresh as the last fetch -- this is what makes them current. --prune is
-- the point of it: without it a branch deleted on the remote keeps its
-- remote-tracking ref and never shows up as [gone].
m.fetch = function(root, on_done)
  run_async(root, { "fetch", "--all", "--prune" }, on_done)
end

-- The commits the preview shows: the branch's full history from its tip, in
-- git's own medium format -- commit/Author/Date/message blocks threaded on
-- the graph -- with short hashes and relative dates.
m.log = function(root, name, on_done)
  local args =
    { "log", "--color=always", "--graph", "--abbrev-commit", "--date=relative", "--decorate", "-n", "300", name, "--" }
  run_async(root, args, function(res)
    on_done(res.code == 0 and res.stdout or "")
  end)
end

return m
