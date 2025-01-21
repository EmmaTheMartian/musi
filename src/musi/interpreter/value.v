module interpreter

import musi.ast { NodeBlock }

pub struct ValueNativeFunction {
pub:
	tracer string
	code   fn (mut Scope) Value @[required]
	args   []string
}

pub fn (func &ValueNativeFunction) run(mut s Scope, args map[string]Value) Value {
	mut scope := s.make_child(func.tracer)
	// add args to scope
	for arg, val in args {
		scope.new(arg, val)
	}
	return func.code(mut scope)
}

pub struct ValueFunction {
pub:
	tracer string
	code   NodeBlock
	args   []string
}

pub fn (func &ValueFunction) run(mut s Scope, args map[string]Value) Value {
	mut scope := s.make_child(func.tracer)
	// add args to scope
	for arg, val in args {
		scope.new(arg, val)
	}
	return scope.eval(func.code)
}

pub type Value = string | int | f32 | ValueFunction | ValueNativeFunction

pub const empty = Value{}
