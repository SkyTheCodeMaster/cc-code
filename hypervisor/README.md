A simple hypervisor that runs the normal program, and a watcher script.
The watcher script has a custom function `getLocals` available to it that returns a read/writeable table of locals for that program.
The `getLocals` function takes a single boolean parameter, `raw`. If `true`, then it will just return an immutable table of `name` -> `value` of locals.
The hypervisor loads the normal script at `script.lua`, and the watcher at `watcher.lua`.
The hypervisor system also includes a basic encryption system, using `chacha20`. A helper library is provided at `libraries/encryption.lua`.