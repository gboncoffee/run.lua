v = vim.api
g = vim.g
r = require "run"
command = v.nvim_create_user_command

if g.autoloaded_run then
    return
end

g.autoloaded_run = true

command("CompileFocus", r.open_compiler, {})
command("CompileAuto", function()
    r.compile_auto(
        v.nvim_buf_get_option(0, "filetype"), 
        v.nvim_buf_get_name(0)
    )
end, {})

command("Compile", function(args)
    r.compile(args.args)
end, {
    complete = "file",
    nargs    = "*",
})

command("CompileReset", function(args)
    r._compile_cmd_reset(args.args)
    r.compile()
end, {
    complete = "file",
    nargs    = "*",
})

command("Run", function(args)
    r.run(args.args)
end, {
    complete = "file",
    nargs    = "*",
})

-- async commands
local complete_async = function(a, c, p)
    local list = {}
    local c    = 1
    for i in pairs(r.async_list()) do
        list[c] = i
    end
    return list
end

command("Async", function(args)
    r.async_start(args.args)
end, {
    complete = "file",
    nargs    = "*",
})

command("AsyncFocus", function(args)
    r.async_buf_open(args.args)
end, {
    complete = complete_async,
    nargs    = "*",
})

command("AsyncKill", function(args)
    r.async_kill(args.args)
end, {
    complete = complete_async,
    nargs    = "*",
})

command("AsyncList", function()
    for i in pairs(r.async_list()) do
        print(i)
    end
end, {})
