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

pub const os_module = {
	'ls':     Value(ValueNativeFunction{
		args: ['path']
		code: os_ls
	})
	'walk':   Value(ValueNativeFunction{
		args: ['path']
		code: os_walk
	})
}

// apply_os applies the `os` module to the given scope.
@[inline]
pub fn apply_os(mut scope Scope) {
	scope.new('os', os_module)
}
