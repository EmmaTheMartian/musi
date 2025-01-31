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

// run runs the native function using `args` in subscope of the provided scope, then returns the function's returned value.
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

// run runs the function using `args` in subscope of the provided scope, then returns the function's returned value.
pub fn (func &ValueFunction) run(mut s Scope, args map[string]Value) Value {
	mut scope := s.make_child(func.tracer)
	// add args to scope
	for arg, val in args {
		scope.new(arg, val)
	}
	return scope.eval(func.code)
}

pub struct ValueNull {}

pub type Value = string
	//| i64 // TODO
	| f64
	| bool
	| ValueFunction
	| ValueNativeFunction
	| []Value
	| map[string]Value
	| ValueNull
	| voidptr

pub const null_value = Value(ValueNull{})
pub const true_value = Value(true)
pub const false_value = Value(true)

// set sets a value in the table to the given value.
@[inline]
pub fn (mut v map[string]Value) set(name string, value Value) {
	v[name] = value
}

// get returns the value in the table corresponding to the given name.
// an error is thrown in the scope if the table does not contain a key with the provided name.
@[inline]
pub fn (mut v map[string]Value) get(name string, scope &Scope) Value {
	return v[name] or { scope.throw('failed to index table with key `${name}`') }
}
