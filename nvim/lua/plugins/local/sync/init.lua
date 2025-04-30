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

local function get_changed_git_files()
  local handle = io.popen("git status --porcelain")
  if not handle then
    return {}, "Error: Could not run git command or not in a git repo"
  end

  local deleted_files = {}
  local changed_files = {}

  for line in handle:lines() do
    local status, file = line:match("^(..)%s+(.*)")

    if status and file then
      if status == "??" then
        -- Untracked files (status ??)
        table.insert(changed_files, file)
      elseif status == " M" then
        -- Modified files (unstaged) (status M)
        table.insert(changed_files, file)
      elseif status == " A" then
        -- Staged new files (status A)
        table.insert(changed_files, file)
      elseif status == "AM" or status == "MM" or status == " M" then
        -- Staged modified files (status M for staged and M for modified)
        table.insert(changed_files, file)
      elseif status == " D" then
        -- Deleted files (status D)
        table.insert(deleted_files, file)
      end
    end
  end

  handle:close() -- Close the handle
  return {
    changed_files = changed_files,
    deleted_files = deleted_files,
  } -- Return the list of changed files
end

local function get_directory_from_path(file_path)
  -- Match everything up to the last slash (directory path)
  local directory = file_path:match("^(.*)/[^/]+$")

  -- If no match is found, return the current path (it's either a root or the file has no directory)
  return directory or file_path
end

local function get_relative_buffer_path(directory)
  local current_file = vim.fn.expand("%:p")

  if not directory:match("/$") then
    directory = directory .. "/"
  end

  local relative_path = current_file:match("^" .. directory .. "(.*)")

  if not relative_path then
    return nil, "The file is not inside the provided directory."
  end

  return relative_path
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
  get_relative_buffer_path = get_relative_buffer_path,
  get_directory_from_path = get_directory_from_path,
  get_changed_git_files = get_changed_git_files,
  run = run_bash_script,
}
