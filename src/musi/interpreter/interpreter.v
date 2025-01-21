module interpreter

import musi.ast { AST, NodeRoot }

@[heap; noinit]
pub struct Interpreter {
pub mut:
	scope Scope
}

@[inline]
pub fn Interpreter.new() Interpreter {
	return Interpreter{
		scope: Scope.new()
	}
}

@[inline]
pub fn (mut i Interpreter) new_scope(tracer string) Scope {
	return i.scope.make_child(tracer)
}

@[inline]
pub fn (mut i Interpreter) run(tree &AST) {
	i.scope.eval(&NodeRoot(tree))
}
