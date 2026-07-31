-- The file tree over the changed paths, and the mark aggregation for dir rows.
--
-- Dir rows speak the same two-column grammar as file rows, with "any"
-- semantics per column:
--
--   staged column     `M` if anything below has staged changes (A/R/D all read
--                     as `M` -- letter fidelity is deliberately collapsed)
--   worktree column   the most urgent state below: `U` > `M` > `?` > blank
--
-- A dir git itself would print as untracked shows `??`. That is a question
-- about the dir ("does it hold no tracked file at all"), not about the rows
-- below it, so it comes from git rather than from tree membership.

local m = {}

-- Staged-side letters, and worktree-side letters, for tracked paths.
local STAGED = { M = true, A = true, D = true, R = true, C = true, T = true }
local DIRTY = { M = true, D = true, T = true, A = true, R = true, C = true }

local function new_dir(name, path)
  return { name = name, path = path, is_dir = true, children = {}, index = {} }
end

local function insert(root, entry)
  local parts = vim.split(entry.path, "/", { plain = true })
  local dir = root

  for i = 1, #parts - 1 do
    local name = parts[i]
    local child = dir.index[name]
    if not child or not child.is_dir then
      child = new_dir(name, dir.path == "" and name or dir.path .. "/" .. name)
      dir.index[name] = child
      table.insert(dir.children, child)
    end
    dir = child
  end

  local name = parts[#parts]
  local file = { name = name, path = entry.path, is_dir = false, entry = entry }
  dir.index[name] = file
  table.insert(dir.children, file)
end

-- Post-order: give every node its marks and the flags the verbs need.
local function aggregate(node)
  if not node.is_dir then
    local entry = node.entry
    node.x, node.y = entry.x, entry.y
    node.conflict = entry.unmerged
    node.staged = not entry.unmerged and STAGED[entry.x] or false
    node.dirty = not entry.unmerged and DIRTY[entry.y] or false
    node.untracked = entry.x == "?"
    node.tracked = entry.x ~= "?"
    return
  end

  local staged, dirty, conflict, untracked, tracked = false, false, false, false, false

  for _, child in ipairs(node.children) do
    aggregate(child)
    staged = staged or child.staged
    dirty = dirty or child.dirty
    conflict = conflict or child.conflict
    untracked = untracked or child.untracked
    tracked = tracked or child.tracked
  end

  node.staged, node.dirty, node.conflict = staged, dirty, conflict
  node.untracked, node.tracked = untracked, tracked
  node.x = staged and "M" or " "
  node.y = (conflict and "U") or (dirty and "M") or (untracked and "?") or " "
end

local function sort(node)
  table.sort(node.children, function(a, b)
    if a.is_dir ~= b.is_dir then
      return a.is_dir
    end
    local an, bn = a.name:lower(), b.name:lower()
    if an == bn then
      return a.name < b.name
    end
    return an < bn
  end)

  for _, child in ipairs(node.children) do
    if child.is_dir then
      sort(child)
    end
  end
end

m.build = function(entries)
  local root = new_dir("", "")
  for _, entry in ipairs(entries) do
    insert(root, entry)
  end
  aggregate(root)
  sort(root)
  return root
end

-- Dirs that might be the `??` case: nothing tracked among their rows. Only
-- might -- a dir can hold a tracked file that is simply unchanged, so it never
-- appears in the tree. Git settles it; see git.untracked_dirs.
m.candidates = function(node, out)
  out = out or {}
  for _, child in ipairs(node.children) do
    if child.is_dir then
      if not child.tracked then
        table.insert(out, child.path)
      end
      m.candidates(child, out)
    end
  end
  return out
end

-- git prints only the topmost untracked dir, so `??` carries down the subtree.
m.apply_untracked = function(node, dirs)
  local function mark(dir)
    dir.x, dir.y = "?", "?"
    for _, child in ipairs(dir.children) do
      if child.is_dir then
        mark(child)
      end
    end
  end

  for _, child in ipairs(node.children) do
    if child.is_dir then
      if dirs[child.path] then
        mark(child)
      else
        m.apply_untracked(child, dirs)
      end
    end
  end
end

-- Flatten to display rows, honouring folds. A dir with a single dir child is
-- collapsed into its child (`lua/plugins/local/`), the row standing for the
-- deepest dir of the chain -- acting on it is the same pathspec either way.
m.rows = function(root, folds)
  local rows = {}

  local function walk(dir, depth)
    for _, child in ipairs(dir.children) do
      if child.is_dir then
        local node, display = child, child.name
        while #node.children == 1 and node.children[1].is_dir do
          node = node.children[1]
          display = display .. "/" .. node.name
        end

        table.insert(rows, { node = node, display = display .. "/", depth = depth, is_dir = true })
        if not folds[node.path] then
          walk(node, depth + 1)
        end
      else
        table.insert(rows, { node = child, display = child.name, depth = depth, is_dir = false })
      end
    end
  end

  walk(root, 0)
  return rows
end

-- Every untracked file below `node`, for previews that have no index side.
m.untracked_files = function(node, out)
  out = out or {}
  if node.is_dir then
    for _, child in ipairs(node.children) do
      m.untracked_files(child, out)
    end
  elseif node.untracked then
    table.insert(out, node.path)
  end
  return out
end

return m
