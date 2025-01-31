# embedding musi

> important:
>
> this document is a work-in-progress, it is currently unfinished!

to embed musi into your projects, you will need to install it from vpm:

```sh
v install EmmaTheMartian.musi
```

then, in your code, you can add the following code:

```v
import emmathemartian.musi.interpreter { Interpreter }

[...]

root_import_dir := os.dir(input_file)
opts := interpreter.InterpreterOptions{}
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

## examples

the `src/main.v` file implements musi in the same way that a program embedding
it would, so you can reference that if you would like!

> do note that it invokes tokenization, parsing, and interpretation in separate
> steps so that i can make debugging tools. this does mean that it is a bad
> reference though!

> if you know of any open-source projects embedding musi that people can
> reference, let me know so i can list them here! and if that project is yours,
> thanks for using musi!
