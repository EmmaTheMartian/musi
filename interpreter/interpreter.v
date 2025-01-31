module interpreter

import os
import ast { AST, NodeRoot }
import tokenizer
import parser

pub struct InterpreterOptions {
pub mut:
	allow_imports bool = true
}

// Interpreter represents an interpretation context, containing the root scope, import information, and interpreter options.
@[heap; noinit]
pub struct Interpreter {
pub mut:
	root_scope       Scope
	import_root_path string
	cached_imports   map[string]Value
	options          InterpreterOptions
	// scope_init_fn is called when new scopes are made under the interpreter (only for root_scope and isolated scopes), this is intended to be used to apply the standard library to scopes.
	scope_init_fn fn (mut Scope) @[required]
}

// Interpreter.new creates a new interpreter and returns a pointer to it.
// `root_path` should be the **directory** of the file executed (for example, if executing `./samples/test.musi`, `root_path` would be `./samples/`)
// `options` contain options for the interpreter, controlling language permissions (i.e, sandboxes).
// `scope_init_fn` is a function called on the interpreter's root scope and any isolated scopes made, this is used to apply the stdlib to scopes.
@[inline]
pub fn Interpreter.new(root_path string, options InterpreterOptions, scope_init_fn fn (mut Scope)) &Interpreter {
	mut i := &Interpreter{
		import_root_path: root_path
		root_scope:       Scope.new(unsafe { nil }, 'program')
		scope_init_fn:    scope_init_fn
	}
	i.root_scope.interpreter = i
	i.scope_init_fn(mut i.root_scope)
	return i
}

// new_scope creates a new child scope under the root scope with the given tracer, then returns it.
@[inline]
pub fn (mut i Interpreter) new_scope(tracer string) Scope {
	return i.root_scope.make_child(tracer)
}

// run evaluates the provided AST in the interpreter's root scope and returns the scope's returned value.
@[inline]
pub fn (mut i Interpreter) run(tree &AST) Value {
	return i.root_scope.eval(&NodeRoot(tree))
}

// run_isolated evaluates the provided AST in the a fresh scope complete detached from the interpreter's root scope and returns the scope's returned value.
// notably, this is used for importing files.
// `init` is called on the scope after making it and before evaluating, you can use it to add the stdlib.
@[inline]
pub fn (mut i Interpreter) run_isolated(tree &AST, tracer string) Value {
	mut scope := Scope.new(i, tracer)
	i.scope_init_fn(mut scope)
	return scope.eval(&NodeRoot(tree))
}

// import evaluates the given file (`${Interpreter.import_root_path}/${module_path}`) if it has not been previously cached, caches it, then returns the imported scope's value.
// if it has been cached, the cached value is returned.
@[inline]
pub fn (mut i Interpreter) import(mut scope Scope, module_path string) Value {
	if !i.options.allow_imports {
		scope.throw('error: import calls are disallowed')
	}

	path := os.join_path(i.import_root_path, module_path)
	if path !in i.cached_imports {
		i.cached_imports[path] = i.run_file_isolated(path)
	}
	return i.cached_imports[path] or {
		scope.throw('error occurred while indexing sumtype map, this should never happen, please report it!')
	}
}

// run_file tokenizes, parses, and interprets the file at the given path.
@[inline]
pub fn (mut i Interpreter) run_file(path string) Value {
	if !os.exists(path) {
		i.root_scope.throw('error: file `${path}` does not exist.')
	}

	s := os.read_file(path) or { i.root_scope.throw('error: failed to read file `${path}`') }

	mut t := tokenizer.Tokenizer{
		input: s
		ilen:  s.len
	}
	t.tokenize()
	ast_ := parser.parse(t.tokens)
	return i.run(ast_)
}

// run_file_isolated is like run_file except executes the file in a scope detached from the interpreter's root scope.
@[inline]
pub fn (mut i Interpreter) run_file_isolated(path string) Value {
	if !os.exists(path) {
		i.root_scope.throw('error: file `${path}` does not exist.')
	}

	s := os.read_file(path) or { i.root_scope.throw('error: failed to read file `${path}`') }

	mut t := tokenizer.Tokenizer{
		input: s
		ilen:  s.len
	}
	t.tokenize()
	ast_ := parser.parse(t.tokens)
	return i.run_isolated(ast_, path)
}
