v = vim.api
g = vim.g
command = v.nvim_create_user_command

if g.autoloaded_run then
    return
end

g.autoloaded_run = true

command("CompileFocus", require "run".open_compiler, {})

command("Compile", function(args)
    require "run".compile(args.args)
end, {
    complete = "file",
    nargs    = "*",
})

command("CompileReset", function(args)
    require "run"._compile_cmd_reset(args.args)
    require "run".compile()
end, {
    complete = "file",
    nargs    = "*",
})

command("Run", function(args)
    require "run".run(args.args)
end, {
    complete = "file",
    nargs    = "*",
})
