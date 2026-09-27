-- Godot integration: Godot itself is configured to use nvim as the external
-- editor and talks to the ./godothost pipe in the project root
-- (Editor Settings -> Text Editor -> External, exec flags:
--  --server ./godothost --remote-send "<C-\><C-N>:e {file}<CR>...").

local function godot_root()
  local cwd = vim.fn.getcwd()
  if vim.uv.fs_stat(cwd .. "/project.godot") then
    return cwd
  end
  return nil
end

-- serverstart fails when the socket file already exists. A live socket means
-- another nvim already serves this project, so leave it alone; a dead one is
-- leftover from a crash, so remove it. sockconnect needs `rpc` or `on_data`,
-- otherwise it throws and every socket looks dead.
local function socket_is_alive(path)
  local ok, chan = pcall(vim.fn.sockconnect, "pipe", path, { rpc = true })
  if ok and chan ~= 0 then
    pcall(vim.fn.chanclose, chan)
    return true
  end
  return false
end

local function serve(path)
  if vim.uv.fs_stat(path) then
    if socket_is_alive(path) then
      vim.notify("godot: " .. path .. " is already served by another nvim", vim.log.levels.INFO)
      return
    end
    vim.uv.fs_unlink(path)
  end

  local ok, err = pcall(vim.fn.serverstart, path)
  if not ok then
    vim.notify("godot: could not listen on " .. path .. ": " .. tostring(err), vim.log.levels.WARN)
  end
end

return {
  "habamax/vim-godot",
  -- ft instead of VimEnter: lazy replays FileType after loading, so the
  -- plugin's ftplugin also applies to a file opened from the command line.
  ft = { "gdscript", "gdshader", "gdresource" },
  cond = function()
    return godot_root() ~= nil
  end,
  -- init runs at startup regardless of the ft trigger, so the pipe exists as
  -- soon as the project is opened, before any .gd file is edited.
  -- lazy runs init even when cond == false, hence the root check again.
  init = function()
    local root = godot_root()
    if root then
      serve(root .. "/godothost")
    end
  end,
}
