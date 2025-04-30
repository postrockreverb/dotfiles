local function get_git_root()
  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  if not handle then
    return
  end

  local result = handle:read("*a")
  handle:close()
  return result:match("^%s*(.-)%s*$") -- Clean the result from extra spaces
end

local function get_script_path(script_name)
  -- Try with cwd

  local cwd = vim.fn.getcwd()

  local script_path = cwd .. "/" .. script_name
  if vim.fn.filereadable(script_path) ~= 0 then
    return script_path
  end

  -- Try with git root

  local git_root = get_git_root()
  if not git_root then
    return
  end

  script_path = git_root .. "/" .. script_name
  if vim.fn.filereadable(script_path) ~= 0 then
    return script_path
  end
end

local function prepare_opts(opts)
  opts = opts or {}
  opts.timeout_ms = opts.timeout_ms or 0
  opts.retries = opts.retries or 0
  opts.success_msg = opts.success_msg or "Script finished successfully"
  opts.retry_msg = opts.retry_msg or "Script failed, retrying..."
  opts.failed_msg = opts.failed_msg or "Script failed"
  return opts
end

-- Function to run the bash script with retries
local function run_bash_script(cmd, opts)
  opts = prepare_opts(opts)

  local retry = 0

  local function run_script()
    vim.fn.jobstart(cmd, {
      on_exit = function(_, code)
        if code == 0 then
          vim.notify(opts.success_msg, vim.log.levels.INFO)
          return
        end

        if retry < opts.retries then
          retry = retry + 1
          vim.notify(opts.retry_msg .. " (" .. retry .. "/" .. opts.retries .. ")", vim.log.levels.WARN)
          vim.defer_fn(run_script, opts.timeout_ms)
          return
        end

        vim.notify(opts.failed_msg, vim.log.levels.ERROR)
      end,
    })
  end

  -- Start the initial script run
  run_script()
end

return {
  get_script_path = get_script_path,
  run = run_bash_script,
}
