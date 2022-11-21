local M = {}
local v = vim.api

-- base function to open the window
M._open_run_window = function(buffer) -- {{{
    return v.nvim_open_win(buffer, true, {
        relative = "editor",
        col      = math.ceil(vim.o.columns * 0.125),
        row      = math.ceil(vim.o.lines   * 0.125),
        width    = math.ceil(vim.o.columns * 0.75),
        height   = math.ceil(vim.o.lines   * 0.75),
    })
end -- }}}

-- base function to open a terminal both for run and compile 
M._open_term = function(cmd) -- {{{
    if not cmd then cmd = "" end

    local buffer = v.nvim_create_buf(false, true)
    M._open_run_window(buffer)

    vim.cmd("term " .. cmd)
    vim.cmd("normal a")

    return buffer
end -- }}}

-- violent and egoist function, gets rid of the buffer after using it
M.run = function(cmd) -- {{{
    local buffer = M._open_term(cmd)
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
        cmd = vim.fn.input("Compiler command: ", "", "file")
        vim.fn.inputrestore()
    end

    M._compile_cmd = cmd
    return cmd
end -- }}}

-- human function, keeps the buffer after using it
M.compile = function(cmd) -- {{{

    if (cmd and cmd ~= "") or (not M._compile_cmd) then
        M._compile_cmd_reset(cmd)
    end

    if (M._compile_buffer) and (v.nvim_buf_is_valid(M._compile_buffer)) then
        v.nvim_buf_delete(M._compile_buffer, { force = true })
    end

    M._compile_buffer = M._open_term(M._compile_cmd)

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
