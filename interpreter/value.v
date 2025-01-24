module interpreter

import ast { NodeBlock }

pub interface IFunctionValue {
	args []string

	run(mut Scope, map[string]Value) Value
}

pub struct ValueNativeFunction implements IFunctionValue {
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

pub struct ValueFunction implements IFunctionValue {
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

pub struct ValueNull { }

pub type Value = string | f64 | bool | ValueFunction | ValueNativeFunction | []Value | ValueNull

pub const null_value = Value(ValueNull{})
pub const true_value = Value(true)
pub const false_value = Value(true)
