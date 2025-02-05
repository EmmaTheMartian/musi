# embedding musi

> [!WARNING]
> this document is a work-in-progress, it is currently unfinished!

to embed musi into your projects, you will need to install it from vpm:

```sh
v install EmmaTheMartian.musi
```

then, in your code, you can add the following code:

```v
import emmathemartian.musi.interpreter

[...]

root_import_dir := os.dir(input_file)
opts := interpreter.InterpreterOptions{}
// this function is invoked to initialize new root scopes and isolated scopes.
// is is NOT called on subscopes!
scope_init_fn := fn [use_stdlib] (mut scope interpreter.Scope) {
	stdlib.apply_stdlib(mut scope)
}

mut i := interpreter.Interpreter.new(root_import_dir, opts, scope_init_fn)
i.run_file('hello.musi')
```

```musi
# hello.musi
println("Hello, World!")
```

## adding symbols

```v
[...]
mut i := interpreter.Interpreter.new([...])

i.new('variable_name', 'Hello, World!')

i.run_file('hello.musi')
```

### adding functions

```v
i.new('function_name', interpreter.ValueNativeFunction{
	args: ['user']
	code: fn (mut scope interpreter.Scope) interpreter.Value {
		user := scope.get_fn_arg[string]('user', 'function_name')
		println('Welcome, ${user}!')
		return interpreter.null_value
	}
})
```

then in musi, you can invoke that function!

```musi
> function_name('Gandalf')
Gandalf
```

## examples

the `src/main.v` file implements musi in the same way that a program embedding
it would, so you can reference that if you would like!

> [!NOTE]
> do note that it invokes tokenization, parsing, and interpretation in separate
> steps so that i can make debugging tools. this does mean that it is a bad
> reference though!

you can also look at `stdlib/*.v` for *plenty* of examples on adding new
functions to musi.

> [!NOTE]
> if you know of any open-source projects embedding musi that people can
> reference, let me know so i can list them here! and if that project is yours,
> thanks for using musi!
