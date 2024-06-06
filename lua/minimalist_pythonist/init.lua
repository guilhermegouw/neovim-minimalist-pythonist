local vim = vim
local api = vim.api
local fn = vim.fn
local uv = vim.loop

local M = {}

-- Function to create a temporary file
local function create_temp_file(content)
    local tmpname = vim.fn.tempname()
    local fd = assert(uv.fs_open(tmpname, "w", 384)) -- 384 is octal for 0600 permissions
    uv.fs_write(fd, content, -1)
    uv.fs_close(fd)
    return tmpname
end

-- Function to read the content of a file
local function read_file(filepath)
    local fd = assert(uv.fs_open(filepath, "r", 438)) -- 438 is octal for 0666 permissions
    local stat = assert(uv.fs_fstat(fd))
    local data = uv.fs_read(fd, stat.size, 0)
    uv.fs_close(fd)
    return data
end

-- Function to format using black and isort
function M.format_code()
    if vim.bo.filetype == 'python' then
        local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, true), "\n")
        local tmpfile = create_temp_file(content)
        local black_cmd = string.format('black --line-length 79 %s', tmpfile)
        local isort_cmd = string.format('isort %s', tmpfile)

        -- Run the commands and capture output
        local black_output = vim.fn.system(black_cmd)
        local black_status = vim.v.shell_error
        local isort_output = vim.fn.system(isort_cmd)
        local isort_status = vim.v.shell_error

        -- Read the formatted content back into the buffer
        local formatted_content = read_file(tmpfile)
        vim.api.nvim_buf_set_lines(0, 0, -1, true, vim.split(formatted_content, "\n"))

        -- Display messages in the command line area
        local messages = {}
        if black_status == 0 then
            table.insert(messages, "Formatted with black")
        else
            table.insert(messages, "Error running black: " .. black_output)
        end

        if isort_status == 0 then
            table.insert(messages, "Sorted imports with isort")
        else
            table.insert(messages, "Error running isort: " .. isort_output)
        end

        for _, msg in ipairs(messages) do
            if msg:match("^Error") then
                vim.cmd('echohl ErrorMsg | echom "' .. msg:gsub('"', '\\"') .. '" | echohl None')
            else
                vim.cmd('echom "' .. msg:gsub('"', '\\"') .. '"')
            end
        end

        -- Avoid pressing ENTER to continue
        vim.cmd('redraw!')

        -- Remove the temporary file
        uv.fs_unlink(tmpfile)
    end
end

-- Function to check with flake8
function M.check_with_flake8()
    if vim.bo.filetype == 'python' then
        local filepath = fn.expand('%:p')
        local flake8_cmd = string.format('flake8 --max-line-length 79 %s', filepath)

        -- Run the command and capture output
        local flake8_output = vim.fn.system(flake8_cmd)
        local flake8_status = vim.v.shell_error

        -- Display flake8 output in the command line area
        local messages = {}
        if flake8_status ~= 0 then
            table.insert(messages, "Flake8 found PEP8 issues:\n" .. flake8_output)
        end

        for _, msg in ipairs(messages) do
            if msg:match("^Flake8 found") then
                for _, line in ipairs(vim.split(msg, "\n")) do
                    vim.cmd('echohl ErrorMsg | echom "' .. line:gsub('"', '\\"') .. '" | echohl None')
                end
            else
                vim.cmd('echom "' .. msg:gsub('"', '\\"') .. '"')
            end
        end
    end
end

-- Setup auto commands
function M.setup_autocmd()
    vim.cmd [[autocmd BufWritePre *.py lua require'user.plugins.minimalist_pythonist'.format_code()]]
    vim.cmd [[autocmd BufWritePost *.py lua require'user.plugins.minimalist_pythonist'.check_with_flake8()]]
end

function M.setup()
    M.setup_autocmd()
end

return M

