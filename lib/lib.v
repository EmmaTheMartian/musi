// lib provides helpers for making extension libraries
module lib

import interpreter { Scope, Value }

@[inline]
pub fn get_fn_arg[T](scope &Scope, name string, fnname string) T {
	if x := scope.get_own(name) {
		if x is T {
			return x as T
		} else {
			panic('musi: ${fnname}: expected type of argument `${name}` to be ${T.name} but it was ${typeof(x).name}')
		}
	} else {
		panic('musi: ${fnname}: argument `${name}` not provided')
	}
}

@[inline]
pub fn get_fn_arg_raw(scope &Scope, name string, fnname string) Value {
	if x := scope.get_own(name) {
		return x
	} else {
		panic('musi: ${fnname}: argument `${name}` not provided')
	}
}

@[inline]
pub fn add_comparison_operator(mut scope Scope, name string, apply fn (a Value, b Value) bool) {
	scope.new(name, interpreter.ValueNativeFunction{
		tracer: name
		args: ['a', 'b']
		code: fn [name, apply] (mut scope Scope) Value {
			a := lib.get_fn_arg_raw(scope, 'a', name)
			b := lib.get_fn_arg_raw(scope, 'b', name)
			return Value(apply(a, b))
		}
	})
}

@[inline]
pub fn add_numeric_comparison_operator(mut scope Scope, name string, apply fn (a f64, b f64) bool) {
	scope.new(name, interpreter.ValueNativeFunction{
		tracer: name
		args: ['a', 'b']
		code: fn [name, apply] (mut scope Scope) Value {
			a := lib.get_fn_arg[f64](scope, 'a', name)
			b := lib.get_fn_arg[f64](scope, 'b', name)
			return Value(apply(a, b))
		}
	})
}

@[inline]
pub fn add_bool_comparison_operator(mut scope Scope, name string, apply fn (a bool, b bool) bool) {
	scope.new(name, interpreter.ValueNativeFunction{
		tracer: name
		args: ['a', 'b']
		code: fn [name, apply] (mut scope Scope) Value {
			a := lib.get_fn_arg[bool](scope, 'a', name)
			b := lib.get_fn_arg[bool](scope, 'b', name)
			return Value(apply(a, b))
		}
	})
}
