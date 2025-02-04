# todo

## in progress

- stdlib
- guides

## planning

- drastically improve error messages
- list index operator

## ideas

- for loops
- coroutines/threading/async/etc
	```musi
	let threading = import(":threading")
	threading.thread(fn do
		println('on another thread!')
	end)
	```
- pure functions
	- could be useful in multithreaded environments to help prevent accidentally accessing the parent scopes and causing weird problems
	```musi
	let my_pure_fn = pure fn a, b do
		return a + b
	end
	# alternate implementation is to just make `purefn` be its own keyword
	```

## done

## graveyard
