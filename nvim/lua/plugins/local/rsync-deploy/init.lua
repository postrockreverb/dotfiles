-- Sync the current working directory to a remote host via rsync.
--
-- Configuration is read from a `.nvim/rsync.lua` file at nvim cwd. The file is a
-- Lua chunk that returns a table with this shape:
--
--   return {
--     remote = {
--       host = "user@example.com",   -- optional; omit for local-to-local
--       path = "/var/www/myproject", -- required
--     },
--     ssh = {                        -- optional
--       port = 2222,
--       key = "~/.ssh/id_ed25519",
--       options = { "-o", "StrictHostKeyChecking=no" },
--     },
--     options = { "-az", "--delete", "--itemize-changes" },
--     whitelist = { "src/***", "package.json" },  -- rsync --include
--     blacklist = { "node_modules", "*.log", ".git" }, -- rsync --exclude
--   }

local m = {}

local function find_config(cwd)
  local path = cwd .. "/.nvim/rsync.lua"
  if vim.fn.filereadable(path) == 1 then
    return path
  end
  return nil
end

local function load_config(path)
  local chunk, load_err = loadfile(path)
  if not chunk then
    return nil, load_err
  end
  local ok, result = pcall(chunk)
  if not ok then
    return nil, result
  end
  if type(result) ~= "table" then
    return nil, ".rsync.lua must return a table"
  end
  return result, nil
end

local function build_ssh_command(ssh)
  if not ssh then
    return nil
  end
  local parts = { "ssh" }
  if ssh.port then
    table.insert(parts, "-p")
    table.insert(parts, tostring(ssh.port))
  end
  if ssh.key then
    table.insert(parts, "-i")
    table.insert(parts, vim.fn.shellescape(vim.fn.expand(ssh.key)))
  end
  for _, opt in ipairs(ssh.options or {}) do
    table.insert(parts, opt)
  end
  if #parts == 1 then
    return nil
  end
  return table.concat(parts, " ")
end

local function build_rsync_args(config, source)
  local args = { "rsync" }

  local options = config.options or { "-az", "--delete" }
  for _, opt in ipairs(options) do
    table.insert(args, opt)
  end

  local ssh_cmd = build_ssh_command(config.ssh)
  if ssh_cmd then
    table.insert(args, "-e")
    table.insert(args, ssh_cmd)
  end

  -- Order matters: rsync applies the first matching filter rule, so
  -- whitelist entries must precede blacklist entries.
  for _, pattern in ipairs(config.whitelist or {}) do
    table.insert(args, "--include=" .. pattern)
  end
  for _, pattern in ipairs(config.blacklist or {}) do
    table.insert(args, "--exclude=" .. pattern)
  end

  table.insert(args, source .. "/")

  local remote = config.remote
  local dest
  if remote.host and remote.host ~= "" then
    dest = remote.host .. ":" .. remote.path
  else
    dest = remote.path
  end
  table.insert(args, dest)

  return args
end

m.sync = function()
  local cwd = vim.fn.getcwd()
  local config_path = find_config(cwd)
  if not config_path then
    vim.notify("rsync-deploy: no .nvim/rsync.lua file in " .. cwd, vim.log.levels.ERROR)
    return
  end

  local config, err = load_config(config_path)
  if not config then
    vim.notify("rsync-deploy: failed to load .rsync.lua — " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  if not (config.remote and config.remote.path) then
    vim.notify("rsync-deploy: .rsync.lua is missing remote.path", vim.log.levels.ERROR)
    return
  end

  local args = build_rsync_args(config, cwd)
  local label = (config.remote.host and (config.remote.host .. ":") or "") .. config.remote.path
  vim.notify("rsync-deploy: syncing → " .. label, vim.log.levels.INFO)

  vim.system(args, { text = true }, function(out)
    vim.schedule(function()
      if out.code == 0 then
        local summary = (out.stdout and #out.stdout > 0) and out.stdout or "done"
        vim.notify("rsync-deploy: ok\n" .. summary, vim.log.levels.INFO)
      else
        vim.notify(
          "rsync-deploy: failed (exit " .. tostring(out.code) .. ")\n" .. (out.stderr or ""),
          vim.log.levels.ERROR
        )
      end
    end)
  end)
end

return m
