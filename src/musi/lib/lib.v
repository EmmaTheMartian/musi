// lib provides helpers for making extension libraries
module lib

import musi.interpreter { Scope }

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
pub fn get_fn_arg_raw(scope &Scope, name string, fnname string) interpreter.Value {
	if x := scope.get_own(name) {
		return x
	} else {
		panic('musi: ${fnname}: argument `${name}` not provided')
	}
}
