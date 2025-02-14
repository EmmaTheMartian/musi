# cheatsheet

> based on <https://devhints.io/lua>

```musi
# comments
# multiline comments do not exist

# literals
'string'
"string"
'strings can
be multiline'
123
1.23
true
false
null

# variables
# initialization requires the `let` keyword
let name = 'Gandalf'
# reassignment does not use the keyword
name = 'Frodo'

# conditionals
if name == 'Gandalf' do
	println('Hello, Gandalf!')
end elseif name == 'Frodo' do
	println('Hello, Frodo!')
end else do
	fprintln('Hello, %!', [name])
end

# functions
# functions are first-class, meaning they must be assigned to a variable
let greet = fn greeting, user do
	fprintln('%, %!', [greeting, user])
end

let return_something = fn do
	# note that `return` cannot return nothing. it needs a value after it.
	# if you want to return nothing, use `return null`
	return 'something'
end

# lists
let names = ['Gandalf', 'Frodo'] # trailing commas are allowed
lists.append(names, 'Bilbo')
lists.get(names, 0) # index operator coming soon

# tables
let names_and_ages = {
	gandalf = 50000,
	frodo = 50,
}
# no `let` needed with tables
names_and_ages.bilbo = 111

# loops
let i = 0
while i > 10 do
	println('Bozo!')
	i = i + 1
end

lists.each(names, fn it do
	println(it)
end)

tables.pairs(names, fn pair do
	fprintln('%=%', [it.key, it.value])
end)
```
