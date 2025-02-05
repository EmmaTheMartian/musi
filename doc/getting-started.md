# getting started

> [!WARNING]
> this document is a work-in-progress, it is currently unfinished!

musi aims to be very simple by default, providing enough to function as a
comfortable scripting language without being bloated, clunky, or tedious.

here is hello world in musi:

```musi
println("Hello, World!")
```

look familiar? welllll,

musi is not going to be entirely familiar, there are notable features that it
lacks and has. here is the rundown:

### has

- pipe operator
	- `"Hello, World!" -> println()` will take the value on the left and pass it
	into `println()` as the first argument.
- top-level returns
	- when a file is `import`ed, the `import` function returns what the file
	returned.
	- this behaviour is taken from lua.

### lacks

- for loops. instead, we use `lists.range(start, end) -> lists.each(function)`
	- this sounds really dicey at first, but it quckly starts to feel natural.
	- i may implement for loops in the future, but right now it is not a top
	priority.

	```musi
	lists.range(0, 10) -> lists.filter(fn it do
		return it % 2 == 0
	end) -> lists.each(fn it do
		println(it)
	end)
	```
