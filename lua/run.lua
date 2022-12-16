local M = {}
local v = vim.api

M._default_compilers = { -- {{{
    rust       = 'cargo test',
    go         = 'go run',
    java       = 'mvn clean test',
    typescript = 'tsc -p package.json',
    coffee     = 'coffee $#',
    ruby       = 'bin/rails test',
    php        = './vendor/bin/phpunit tests',
    scdoc      = 'scdoc < $# > $#.1',
    markdown   = 'mdcat $#',
    tex        = 'pdflatex $# && pdflatex $#',
    javascript = 'node $#',
    julia      = 'julia $#',
    python     = 'python $#',
    lua        = 'luajit $#',
    sh         = 'sh $#',
    perl       = 'perl $#',
    pascal     = 'fpc $#',
    c          = 'make',
    cpp        = 'make',
    fortran    = 'make',
    asm        = 'make',
    make       = 'make',
} -- }}}

M.set_default_compilers = function(new_def)
    for filetype, compiler in pairs(new_def) do
        M._default_compilers.filetype = compiler
    end
end

M.compile_auto = function(filetype, filename)
    local cmd = M._default_compilers[filetype]
    M._compile_cmd = string.gsub(cmd, "$#", filename)
    M.compile()
end

-- base function to open the window
M._open_run_window = function(buffer) -- {{{
    return v.nvim_open_win(buffer, true, {
        relative = "editor",
        col      = math.ceil(vim.o.columns * 0.125),
        row      = math.ceil(vim.o.lines   * 0.125),
        width    = math.ceil(vim.o.columns * 0.75 - 2),
        height   = math.ceil(vim.o.lines   * 0.75 - 2),
        border   = "rounded"
    })
end -- }}}

-- base function to open a terminal any command
M._open_term = function(cmd) -- {{{
    if not cmd then cmd = "" end

    local buffer = v.nvim_create_buf(false, true)
    M._open_run_window(buffer)

    vim.cmd("term " .. cmd)

    return buffer
end -- }}}

-- async job support {{{
M._async_jobs = {
    -- job = buffer
}

M.async_start = function(job)
    local buffer = M._open_term(job)
    v.nvim_buf_set_option(buffer, "buflisted", false)
    v.nvim_buf_set_option(buffer, "filetype",  "run-async")
    -- use q and esc to quit window but keep buffer opened
    v.nvim_buf_set_keymap(buffer, "n", "q",     ":q<CR>", {})
    v.nvim_buf_set_keymap(buffer, "n", "<Esc>", ":q<CR>", {})

    -- add to jobs list
    M._async_jobs[job] = buffer

    v.nvim_create_autocmd({ "TermClose" }, {
        buffer   = buffer,
        callback = function()
            v.nvim_echo({ { "Your job " .. job .. " just stopped.", "Error" } }, true, {})
        end
    })
end

M.async_buf_open = function(job)
    M._open_run_window(M._async_jobs[job])
end

M.async_kill = function(job)
    v.nvim_buf_delete(M._async_jobs[job], { force = true})
    M._async_jobs[job] = nil
end

-- we need to use this because there's anyway we can hook on the deletion of
-- terminal output buffers
M.async_list = function()
    local jobs_with_buf = {}
    for job, buffer in pairs(M._async_jobs) do
        if v.nvim_buf_is_valid(buffer) then
            jobs_with_buf[job] = buffer
        end
    end
    M._async_jobs = jobs_with_buf
    return M._async_jobs
end

-- }}}

-- violent and egoist function, gets rid of the buffer after using it
M.run = function(cmd) -- {{{
    local buffer = M._open_term(cmd)
    vim.cmd("normal a")
    vim.bo.bufhidden = "wipe"
    v.nvim_create_autocmd({ "TermClose" }, {
        buffer = buffer,
        callback = function()
            v.nvim_buf_delete(buffer, {})
        end
    })
end -- }}}

-- simple and ez way to reset the cmd
M._compile_cmd_reset = function(cmd) -- {{{
    if (not cmd) or (cmd == "") then
        vim.fn.inputsave()
        cmd = vim.fn.input("Compiler command: ", M._compile_cmd)
        vim.fn.inputrestore()
    end

    if cmd ~= "" then
        M._compile_cmd = cmd
    end

    return cmd
end -- }}}

-- human function, keeps the buffer after using it
M.compile = function(cmd) -- {{{

    if not M._compile_cmd then
        M._compile_cmd = ""
    end

    if cmd and cmd ~= "" then
        M._compile_cmd = cmd 
    elseif M._compile_cmd == "" then
        M._compile_cmd_reset(cmd)
        if M._compile_cmd == "" then
            return
        end
    end

    if (M._compile_buffer) and (v.nvim_buf_is_valid(M._compile_buffer)) then
        v.nvim_buf_delete(M._compile_buffer, { force = true })
    end

    M._compile_buffer = M._open_term(M._compile_cmd)
    vim.cmd("normal a")
    -- set nobuflisted so it don't show up in :ls nor jumplist
    v.nvim_buf_set_option(M._compile_buffer, "buflisted", false)


    v.nvim_create_autocmd({ "TermClose" }, {
        buffer = M._compile_buffer,
        callback = function()
            -- go to normal mode after the compiler exits
            local keys = v.nvim_replace_termcodes("<C-\\>", true, false, true)
            local keys = keys .. v.nvim_replace_termcodes("<C-n>", true, false, true)
            v.nvim_feedkeys(keys, "n", false)

            -- use q and esc to quit window but keep compiler buffer opened
            -- "minimized"
            v.nvim_buf_set_keymap(M._compile_buffer, "n", "q",     ":q<CR>", {})
            v.nvim_buf_set_keymap(M._compile_buffer, "n", "<Esc>", ":q<CR>", {})
        end
    })

    vim.cmd("normal a")
    v.nvim_buf_set_option(M._compile_buffer, "filetype", "run-compiler")

end -- }}}

M.open_compiler = function()
    M._open_run_window(M._compile_buffer)
end

return M
