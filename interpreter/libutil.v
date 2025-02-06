// provides helpers for making extension libraries
module interpreter

// get_fn_arg gets a variable from the provided scope (and not from parent scopes) and casts it to T.
// if the variable does not exist, an error is thrown.
// see also: get_fn_arg_raw
@[inline]
pub fn (scope &Scope) get_fn_arg[T](name string, fnname string) T {
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

// get_fn_arg_raw gets a variable from the provided scope (and not from parent scopes) without casting it.
// if the variable does not exist, an error is thrown.
// see also: get_fn_arg
@[inline]
pub fn (scope &Scope) get_fn_arg_raw(name string, fnname string) Value {
	if x := scope.get_own(name) {
		return x
	} else {
		panic('musi: ${fnname}: argument `${name}` not provided')
	}
}

// get_fn_arg_ptr gets a pointer to a variable from the provided scope (and not from parent scopes) and casts it to T.
// if the variable does not exist, an error is thrown.
// see also: get_fn_arg_raw
@[inline]
pub fn (scope &Scope) get_fn_arg_ptr[T](name string, fnname string) &T {
	if x := scope.get_own_ptr(name) {
		if x is T {
			return &x as &T
		} else {
			scope.throw('${fnname}: expected type of argument `${name}` to be ${T.name} but it was ${typeof(x).name}')
		}
	} else {
		scope.throw('${fnname}: argument `${name}` not provided')
	}
}

// get_fn_arg_raw_ptr gets a pointer to a variable from the provided scope (and not from parent scopes) without casting it.
// if the variable does not exist, an error is thrown.
// see also: get_fn_arg
@[inline]
pub fn (scope &Scope) get_fn_arg_raw_ptr(name string, fnname string) &Value {
	if x := scope.get_own_ptr(name) {
		return &x
	} else {
		panic('musi: ${fnname}: argument `${name}` not provided')
	}
}

pub struct MusiModule {
pub:
	name string
}

pub fn MusiModule.apply[T](instance &T, mut scope Scope) {
	mut functions := map[string]Value{}
	$for method in T.methods {
		mut args := []string{}
		$for attr in method.attributes {
			if attr.name == 'params' {
				for param in attr.arg.split(',') {
					args << param.trim_space()
				}
			}
		}
		closure := fn [instance, method] (mut scope Scope) Value {
			func := instance.$(method.name)
			return func(mut scope)
		}
		functions[method.name] = ValueNativeFunction{
			args: args
			code: closure
		}
	}
	scope.new(instance.name, functions)
}
