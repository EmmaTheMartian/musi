module interpreter

import os
import ast { AST, NodeRoot }
import tokenizer
import parser

pub struct InterpreterOptions {
pub mut:
	use_stdlib    bool = true
	allow_imports bool = true
}

@[heap; noinit]
pub struct Interpreter {
pub mut:
	root_scope       Scope
	import_root_path string
	cached_imports   map[string]Value
	options          InterpreterOptions
}

@[inline]
pub fn Interpreter.new(root_path string, options InterpreterOptions) &Interpreter {
	mut i := &Interpreter{
		import_root_path: root_path
		root_scope:       Scope.new(unsafe { nil }, 'program')
	}
	i.root_scope.interpreter = i
	if i.options.use_stdlib {
		apply_builtins(mut i.root_scope)
	}
	return i
}

@[inline]
pub fn (mut i Interpreter) new_scope(tracer string) Scope {
	return i.root_scope.make_child(tracer)
}

@[inline]
pub fn (mut i Interpreter) run(tree &AST) Value {
	return i.root_scope.eval(&NodeRoot(tree))
}

@[inline]
pub fn (mut i Interpreter) run_isolated(tree &AST, tracer string) Value {
	mut scope := Scope.new(i, tracer)
	if i.options.use_stdlib {
		apply_builtins(mut scope)
	}
	return scope.eval(&NodeRoot(tree))
}

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

// run_file_isolated is like run_file except executes the file in an isolated
// scope.
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
