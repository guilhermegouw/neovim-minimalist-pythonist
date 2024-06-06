-- Minimalist Pythonist Initialization
local M = {}

-- Utility function to get the Python executable from the virtual environment
local function get_python_executable()
    local venv_path = os.getenv('VIRTUAL_ENV') or (vim.fn.getcwd() .. '/.venv')
    if vim.fn.executable(venv_path .. '/bin/python') == 1 then
        return venv_path .. '/bin/python'
    end
    return 'python'
end

-- Function to run shell commands and capture output
local function run_command(command)
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    return result
end

-- Format and Lint on Save
function M.format_and_lint()
    local python_executable = get_python_executable()
    local current_file = vim.api.nvim_buf_get_name(0)
    
    -- Run black with line length 79
    local black_command = string.format("%s -m black --line-length 79 %s", python_executable, current_file)
    print(run_command(black_command))
    
    -- Run isort with line length 79
    local isort_command = string.format("%s -m isort --line-length 79 %s", python_executable, current_file)
    print(run_command(isort_command))
    
    -- Run flake8 with max line length 79
    local flake8_command = string.format("%s -m flake8 --max-line-length 79 %s", python_executable, current_file)
    print(run_command(flake8_command))
end

-- Jedi-based code navigation
local function jedi_command(command)
    local python_executable = get_python_executable()
    local current_line = vim.api.nvim_get_current_line()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1], cursor[2]
    local filename = vim.api.nvim_buf_get_name(0)

    local script = string.format([[
    import jedi
    script = jedi.Script(%q, %d, %d, %q)
    result = script.%s()
    for item in result:
        print(item)
    ]], current_line, row, col, filename, command)

    local cmd = string.format("%s -c %q", python_executable, script)
    local result = run_command(cmd)
    print(result)
end

function M.go_to_definition()
    jedi_command('goto_definitions')
end

function M.find_references()
    jedi_command('get_references')
end

function M.go_to_implementation()
    jedi_command('goto_assignments')
end

function M.show_documentation()
    jedi_command('help')
end

-- Keybindings for navigation
function M.setup_keybindings()
    vim.api.nvim_set_keymap('n', 'gd', ':lua require"minimalist_pythonist".go_to_definition()<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', 'gr', ':lua require"minimalist_pythonist".find_references()<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', 'gi', ':lua require"minimalist_pythonist".go_to_implementation()<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', 'K', ':lua require"minimalist_pythonist".show_documentation()<CR>', { noremap = true, silent = true })
end

-- Autocmd to format on save
function M.setup_autocmd()
    vim.cmd [[autocmd BufWritePre *.py lua require'minimalist_pythonist'.format_and_lint()]]
end

function M.setup()
    M.setup_keybindings()
    M.setup_autocmd()
end

return M

