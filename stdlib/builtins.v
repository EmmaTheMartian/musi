module stdlib

import interpreter { Scope, Value, ValueFunction, ValueNativeFunction, ValueNull }

@[inline]
fn import_(mut scope Scope) Value {
	return scope.import(scope.get_fn_arg[string]('module', 'import'))
}

@[inline]
fn tostring(mut scope Scope) Value {
	return scope.get_fn_arg_raw('thing', 'tostring').to_string()
}

@[inline]
fn tonumber(mut scope Scope) Value {
	thing := scope.get_fn_arg_raw('thing', 'tonumber')
	match thing {
		string {
			return thing.f64()
		}
		f64 {
			return thing
		}
		else {
			scope.throw('tonumber: cannot cast ${typeof(thing).name} to number')
		}
	}
}

@[inline]
fn typeof_(mut scope Scope) Value {
	return match scope.get_fn_arg_raw('it', 'typeof') {
		string { 'string' }
		f64 { 'float' }
		bool { 'bool' }
		ValueFunction { 'fn' }
		ValueNativeFunction { 'nfn' }
		[]Value { 'list' }
		map[string]Value { 'table' }
		ValueNull { 'null' }
		voidptr { 'voidptr' }
	}
}

@[inline]
fn print_(mut scope Scope) Value {
	text := scope.get_fn_arg_raw('text', 'print')
	print(scope.invoke('tostring', {
		'thing': text
	}) as string)
	return interpreter.null_value
}

@[inline]
fn println_(mut scope Scope) Value {
	text := scope.get_fn_arg_raw('text', 'println')
	println(scope.invoke('tostring', {
		'thing': text
	}) as string)
	return interpreter.null_value
}

@[inline]
fn fprint_(mut scope Scope) Value {
	text := scope.get_fn_arg[string]('text', 'fprint')
	values := scope.get_fn_arg[[]Value]('values', 'fprint')
	func := (scope.get('strings') or {
		scope.throw('fprintln requires the `strings` module, but it is not present.')
	} as map[string]Value)['format'] or {
		scope.throw('fprintln: could not find `strings.format`')
	}
	print(scope.eval_function(func, {'string': text, 'values': values }, 'format') as string)
	return interpreter.null_value
}

@[inline]
fn fprintln_(mut scope Scope) Value {
	text := scope.get_fn_arg[string]('text', 'fprintln')
	values := scope.get_fn_arg[[]Value]('values', 'fprintln')
	func := (scope.get('strings') or {
		scope.throw('fprintln requires the `strings` module, but it is not present.')
	} as map[string]Value)['format'] or {
		scope.throw('fprintln: could not find `strings.format`')
	}
	println(scope.eval_function(func, {'string': text, 'values': values }, 'format') as string)
	return interpreter.null_value
}

@[inline]
fn panic_(mut scope Scope) Value {
	text := scope.get_fn_arg_raw('text', 'panic')
	scope.throw(scope.invoke('tostring', {
		'thing': text
	}) as string)
	return interpreter.null_value
}

@[inline]
fn gettrace(mut scope Scope) Value {
	return scope.interpreter.stacktrace.array().map(|it| Value('${it.file}:${it.source}:${it.line}:${it.column}'))
}

pub const builtins = {
	'import':   Value(ValueNativeFunction{
		args:   ['module']
		code:   import_
	})
	'tostring': ValueNativeFunction{
		args:   ['thing']
		code:   tostring
	}
	'tonumber': ValueNativeFunction{
		args:   ['thing']
		code:   tonumber
	}
	'typeof':   ValueNativeFunction{
		args:   ['it']
		code:   typeof_
	}
	'print':    ValueNativeFunction{
		args:   ['text']
		code:   print_
	}
	'println':  ValueNativeFunction{
		args:   ['text']
		code:   println_
	}
	'fprint':    ValueNativeFunction{
		args:   ['text', 'values']
		code:   fprint_
	}
	'fprintln':  ValueNativeFunction{
		args:   ['text', 'values']
		code:   fprintln_
	}
	'panic':    ValueNativeFunction{
		args:   ['text']
		code:   panic_
	}
	'gettrace': ValueNativeFunction{
		args: []
		code: gettrace
	}
}

// apply_builtins adds all builtin functions to the given scope.
@[inline]
pub fn apply_builtins(mut scope Scope) {
	for name, value in builtins {
		scope.new(name, value)
	}
}
