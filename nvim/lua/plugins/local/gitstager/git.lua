-- Thin wrapper over the git CLI.
--
-- Everything runs with `cwd = root`, so every path handed in or out of this
-- module is relative to the repository root.

local m = {}

-- The seven `XY` pairs that mean "unmerged" rather than "staged X, dirty Y".
local UNMERGED = {
  DD = true,
  AU = true,
  UD = true,
  UA = true,
  DU = true,
  AA = true,
  UU = true,
}

local function run(root, args)
  local cmd = { "git" }
  vim.list_extend(cmd, args)
  return vim.system(cmd, { cwd = root, text = true }):wait()
end

-- Reads go through this: `git status` is ~100ms on a large repo and there is no
-- flag that makes it cheaper, so it must not be on the main loop. `on_done` is
-- called off the main loop -- schedule anything that touches a buffer.
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

m.has_head = function(root)
  return run(root, { "rev-parse", "--verify", "--quiet", "HEAD" }).code == 0
end

-- `git status --porcelain=v1 -z -uall`, one entry per changed path.
--
-- The -z form is unquoted and NUL-separated, so paths with spaces, quotes or
-- newlines survive intact. Rename/copy entries are followed by a second NUL
-- terminated token holding the original path.
local function parse_status(res)
  if res.code ~= 0 then
    return nil, m.err(res)
  end

  local tokens = vim.split(res.stdout or "", "\0", { plain = true })
  local entries = {}
  local i = 1

  while i <= #tokens do
    local token = tokens[i]
    i = i + 1
    if #token > 3 then
      local x, y, path = token:sub(1, 1), token:sub(2, 2), token:sub(4)
      if x == "R" or x == "C" then
        -- Skip the original path: the row stands for where the file is now.
        i = i + 1
      end
      table.insert(entries, {
        path = path,
        x = x,
        y = y,
        unmerged = UNMERGED[x .. y] or false,
      })
    end
  end

  return entries
end

m.status = function(root, on_done)
  run_async(root, { "status", "--porcelain=v1", "-z", "--untracked-files=all" }, function(res)
    on_done(parse_status(res))
  end)
end

-- Candidates whose parent is also a candidate need no query of their own: the
-- output for the parent already covers everything below it.
local function topmost(dirs)
  local set = {}
  for _, dir in ipairs(dirs) do
    set[dir] = true
  end

  local out = {}
  for _, dir in ipairs(dirs) do
    local covered = false
    local at = dir:match("^(.*)/[^/]*$")
    while at do
      if set[at] then
        covered = true
        break
      end
      at = at:match("^(.*)/[^/]*$")
    end
    if not covered then
      table.insert(out, dir)
    end
  end
  return out
end

-- Which of `candidates` git itself would call untracked: the ones holding no
-- tracked file at all. `ls-files --cached` is the literal definition of tracked
-- and reads the index instead of walking the worktree -- ~16ms where a second
-- `git status` costs 50-90ms.
m.untracked_dirs = function(root, candidates, on_done)
  if #candidates == 0 then
    return on_done({})
  end

  local args = { "ls-files", "-z", "--cached", "--" }
  vim.list_extend(args, topmost(candidates))

  run_async(root, args, function(res)
    local paths = vim.split(res.stdout or "", "\0", { plain = true })
    local dirs = {}

    for _, dir in ipairs(candidates) do
      local prefix = dir .. "/"
      local tracked = false
      for _, path in ipairs(paths) do
        if path:sub(1, #prefix) == prefix then
          tracked = true
          break
        end
      end
      if not tracked then
        dirs[dir] = true
      end
    end

    on_done(dirs)
  end)
end

m.stage = function(root, path)
  return run(root, { "add", "-A", "--", path })
end

m.unstage = function(root, path)
  if m.has_head(root) then
    return run(root, { "reset", "-q", "HEAD", "--", path })
  end
  return run(root, { "rm", "-r", "-q", "--cached", "--", path })
end

-- Throw away everything under `path`: index and worktree back to HEAD, then
-- remove whatever git never tracked.
m.discard = function(root, path, tracked, untracked)
  if tracked then
    local res
    if m.has_head(root) then
      res = run(root, { "restore", "--source=HEAD", "--staged", "--worktree", "--", path })
    else
      -- Unborn branch: there is no HEAD to restore from, so the staged content
      -- becomes untracked and the clean below removes it.
      res = run(root, { "rm", "-r", "-q", "--cached", "--", path })
      untracked = true
    end
    if res.code ~= 0 then
      return res
    end
  end

  if untracked then
    return run(root, { "clean", "-fdq", "--", path })
  end

  return { code = 0 }
end

m.has_staged = function(root)
  return run(root, { "diff", "--cached", "--quiet", "--no-ext-diff" }).code ~= 0
end

m.commit = function(root, message)
  return run(root, { "commit", "-m", message })
end

-- One side of the change at a time, matching the two mark columns: --cached is
-- the index against HEAD (the X column), plain diff is the worktree against the
-- index (the Y column). Neither names HEAD, so both work on an unborn branch.
m.diff = function(root, path, staged, on_done)
  local args = { "diff", "--no-ext-diff" }
  if staged then
    table.insert(args, "--cached")
  end
  vim.list_extend(args, { "--", path })
  run_async(root, args, function(res) on_done(res.stdout or "") end)
end

-- What is still there to throw away under `path`, for the discard confirm: a
-- pathspec-limited status, so it stays cheap even on a large repo.
m.changes_under = function(root, path)
  local res = run(root, { "status", "--porcelain=v1", "-z", "--untracked-files=all", "--", path })
  if res.code ~= 0 then
    return 0
  end

  local n = 0
  for _, token in ipairs(vim.split(res.stdout or "", "\0", { plain = true })) do
    if #token > 3 then
      n = n + 1
    end
  end
  return n
end

return m
