# run.lua

Simple compiling and testing automation for Neovim. Basically a rewrite of
[run.vim](https://github.com/gboncoffee/run.vim) but in Lua. Currently doesn't
support everything that's on the VimScript version.

## Usage

### Run
`Run` will start a process on the `terminal` on a floating window and
automatically enter terminal mode and close the window when the process ends.
You may use args to define a process (for example, `Run python` will start a
Python repl), and, if called without args, it will default to the `shell` Vim
variable.

### Compile
`Compile` will start a process like `Run`, but will leave the terminal buffer
(if one) opened when finished, so the output is persistent. You can close the
window and then check it again with `CompileFocus`.

The main difference it's that when calling `Compile` with args, it'll set the
variable inside the plugin Lua namespace to them, and if calling it without
args, it'll run whatever is in that variable.

This way, you can set the compiling command only once within a session. After
that, you can simply use `Compile` to run the same command again.

If the command is runned and the variable is empty or don't exist, the
user will be prompted with a command to set it to.

### CompileReset
`CompileReset` resets the compiler command variable and them runs `Compile`,
resulting in the `Compile` command prompting the user for a new command. Works
only for forcing the reset of the command and prompting for a new one.

### CompileAuto
Like `CompileReset` but runs the auto-setting function before asking a command
again. See the configuration section for reference.

### Async
`Async` runs a command without entering terminal mode, and you can close the
window to continue your work while the command is running. You will be warned
if the async process stop.

### AsyncList
`AsyncList` lists the processes openend by `Async`.

### AsyncKill 
`AsyncKill` kills a process opened by `Async`.

### AsyncFocus
`AsyncFocus` opens the window with the terminal of an async process.

## Configuration

To set the default compilers used by `CompileAuto`, run the Lua function
`set_default_compilers(def)` from the plugin namespace with a table with the
format `filetype = command` . To use the buffer name in the command, use the
placeholder `$#`. The plugin defaults will not be erased.

Example with the defaults:

```lua
    require "run".set_default_compilers {
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
    }
```
