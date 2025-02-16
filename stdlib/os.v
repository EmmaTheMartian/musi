module stdlib

import os
import interpreter { Scope, Value, ValueNativeFunction }

@[inline]
fn os_ls(mut scope Scope) Value {
	path := scope.get_fn_arg[string]('path', 'ls')
	return os.ls(path) or { scope.throw('ls: no such directory: ${path}') }.map(|it| Value(it))
}

@[inline]
fn os_walk(mut scope Scope) Value {
	path := scope.get_fn_arg[string]('path', 'walk')
	if !os.exists(path) {
		scope.throw('walk: no such directory: ${path}')
	}
	return os.walk_ext(path, '').map(|it| Value(it))
}

pub const os_module = [
	ValueNativeFunction.new('ls', ['path'], os_ls),
	ValueNativeFunction.new('walk', ['path'], os_walk),
]

// apply_os applies the `os` module to the given scope.
@[inline]
pub fn apply_os(mut scope Scope) {
	mut mod := map[string]Value{}
	for func in os_module {
		mod[func.tracer.source] = func
	}
	scope.new('os', mod)
}
