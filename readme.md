# musi

> noun: game, art
>
> adjective: entertaining, artistic, amusing
>
> verb: to amuse, to play, to have fun
>
> *(toki pona)*

musi is an artistic programming language for creating cohesive domain specific
languages.

## plans

<!-- by default, musi has no syntax. all of that is defined by the domain's
implementation. however, musi has a scripting language included in the
`musi/scripting/` folder. it looks like this: -->

```musi
# functions are called with the colon operator (:)
print: 'hello, world!';

const User = fn (name, age)
	const user = [
		pair: 'name' to name,
		pair: 'age' to age
	];
end;

const gandalf = User:

# named arguments do not use = or anything, we just use the argument's name,
# then its value
const numbers = range: from 0 to 10;

# for functions without named arguments, we use commas (,) to separate values.
list.each: numbers fn (it)
	print: it;
end;

# the above could also be written as
list.each: numbers, print;
```
