// provides helpers for making extension libraries
module interpreter

// get_fn_arg gets a variable from the provided scope (and not from parent scopes) and casts it to T.
// if the variable does not exist, an error is thrown.
// see also: get_fn_arg_raw
@[inline]
pub fn get_fn_arg[T](scope &Scope, name string, fnname string) T {
	if x := scope.get_own(name) {
		if x is T {
			return x as T
		} else {
			scope.throw('${fnname}: expected type of argument `${name}` to be ${T.name} but it was ${typeof(x).name}')
		}
	} else {
		scope.throw('${fnname}: argument `${name}` not provided')
	}
}

// get_fn_arg gets a variable from the provided scope (and not from parent scopes) without casting it.
// if the variable does not exist, an error is thrown.
// see also: get_fn_arg
@[inline]
pub fn get_fn_arg_raw(scope &Scope, name string, fnname string) Value {
	if x := scope.get_own(name) {
		return x
	} else {
		panic('musi: ${fnname}: argument `${name}` not provided')
	}
}

// add_comparison_operator is a shorthand for adding a simple `fn (Value, Value) bool` comparison operator to the provided scope.
@[inline]
pub fn add_comparison_operator(mut scope Scope, name string, apply fn (a Value, b Value) bool) {
	scope.new(name, ValueNativeFunction{
		tracer: name
		args:   ['a', 'b']
		code:   fn [name, apply] (mut scope Scope) Value {
			a := get_fn_arg_raw(scope, 'a', name)
			b := get_fn_arg_raw(scope, 'b', name)
			return Value(apply(a, b))
		}
	})
}

// add_numeric_comparison_operator is a shorthand for adding a simple `fn (f64, f64) bool` comparison operator to the provided scope.
@[inline]
pub fn add_numeric_comparison_operator(mut scope Scope, name string, apply fn (a f64, b f64) bool) {
	scope.new(name, ValueNativeFunction{
		tracer: name
		args:   ['a', 'b']
		code:   fn [name, apply] (mut scope Scope) Value {
			a := get_fn_arg[f64](scope, 'a', name)
			b := get_fn_arg[f64](scope, 'b', name)
			return Value(apply(a, b))
		}
	})
}

// add_bool_operator is a shorthand for adding a simple `fn (bool, bool) bool` comparison operator to the provided scope.
@[inline]
pub fn add_bool_comparison_operator(mut scope Scope, name string, apply fn (a bool, b bool) bool) {
	scope.new(name, ValueNativeFunction{
		tracer: name
		args:   ['a', 'b']
		code:   fn [name, apply] (mut scope Scope) Value {
			a := get_fn_arg[bool](scope, 'a', name)
			b := get_fn_arg[bool](scope, 'b', name)
			return Value(apply(a, b))
		}
	})
}
