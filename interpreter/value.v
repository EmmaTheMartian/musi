module interpreter

import ast { NodeBlock }

pub interface IFunctionValue {
	args []string

	run(mut Scope, map[string]Value, string) Value
}

pub struct ValueNativeFunction implements IFunctionValue {
pub:
	code   fn (mut Scope) Value @[required]
	args   []string
}

// run runs the native function using `args` in subscope of the provided scope, then returns the function's returned value.
// `tracer` is used to add the function's name to the stacktrace.
pub fn (func &ValueNativeFunction) run(mut s Scope, args map[string]Value, tracer string) Value {
	s.interpreter.push_trace(s.file, tracer, -1, -1) //TODO: add line/column
	mut scope := s.make_child()
	// add args to scope
	for arg, val in args {
		scope.new(arg, val)
	}
	returned := func.code(mut scope)
	s.interpreter.pop_trace()
	return returned
}

pub struct ValueFunction implements IFunctionValue {
pub:
	code   NodeBlock
	args   []string
}

// run runs the function using `args` in subscope of the provided scope, then returns the function's returned value.
// `tracer` is used to add the function's name to the stacktrace.
pub fn (func &ValueFunction) run(mut s Scope, args map[string]Value, tracer string) Value {
	s.interpreter.push_trace(s.file, tracer, func.code.line, func.code.column)
	mut scope := s.make_child()
	// add args to scope
	for arg, val in args {
		scope.new(arg, val)
	}
	returned := scope.eval(func.code)
	s.interpreter.pop_trace()
	return returned
}

pub struct ValueNull {}

pub type Value = string
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

// to_string converts the value to a string.
pub fn (v &Value) to_string() string {
	match v {
		string {
			return v
		}
		f64 {
			return v.str()
		}
		bool {
			return v.str()
		}
		ValueFunction {
			return 'fn'
		}
		ValueNativeFunction {
			return 'nativefn'
		}
		[]Value {
			return v.str()
			// return Value('list')
		}
		map[string]Value {
			return v.str()
			// return Value('table')
		}
		ValueNull {
			return 'null'
		}
		voidptr { return 'voidptr' }
	}
}
