module stdlib

import interpreter { Scope, Value, ValueFunction, ValueNativeFunction, ValueNull }

@[inline]
fn builtin_import(mut scope Scope) Value {
	return scope.import(scope.get_fn_arg[string]('module', 'import'))
}

@[inline]
fn builtin_tostring(mut scope Scope) Value {
	return scope.get_fn_arg_raw('thing', 'tostring').to_string()
}

@[inline]
fn builtin_tonumber(mut scope Scope) Value {
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
fn builtin_typeof(mut scope Scope) Value {
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
fn builtin_print(mut scope Scope) Value {
	text := scope.get_fn_arg_raw('text', 'print')
	print(scope.invoke('tostring', {
		'thing': text
	}) as string)
	return interpreter.null_value
}

@[inline]
fn builtin_println(mut scope Scope) Value {
	text := scope.get_fn_arg_raw('text', 'println')
	println(scope.invoke('tostring', {
		'thing': text
	}) as string)
	return interpreter.null_value
}

@[inline]
fn builtin_fprint(mut scope Scope) Value {
	text := scope.get_fn_arg[string]('text', 'fprint')
	values := scope.get_fn_arg[[]Value]('values', 'fprint')
	func := (scope.get('strings') or {
		scope.throw('fprintln requires the `strings` module, but it is not present.')
	} as map[string]Value)['format'] or { scope.throw('fprintln: could not find `strings.format`') }
	print(scope.eval_function(func, {
		'string': text
		'values': values
	}) as string)
	return interpreter.null_value
}

@[inline]
fn builtin_fprintln(mut scope Scope) Value {
	text := scope.get_fn_arg[string]('text', 'fprintln')
	values := scope.get_fn_arg[[]Value]('values', 'fprintln')
	func := (scope.get('strings') or {
		scope.throw('fprintln requires the `strings` module, but it is not present.')
	} as map[string]Value)['format'] or { scope.throw('fprintln: could not find `strings.format`') }
	println(scope.eval_function(func, {
		'string': text
		'values': values
	}) as string)
	return interpreter.null_value
}

@[inline]
fn builtin_panic(mut scope Scope) Value {
	text := scope.get_fn_arg_raw('text', 'panic')
	scope.throw(scope.invoke('tostring', {
		'thing': text
	}) as string)
	return interpreter.null_value
}

@[inline]
fn builtin_gettrace(mut scope Scope) Value {
	return scope.interpreter.stacktrace.array().map(|it| Value('${it.file}:${it.source}:${it.line}:${it.column}'))
}

pub const builtins = [
	ValueNativeFunction.new('import', ['module'], builtin_import),
	ValueNativeFunction.new('tostring', ['thing'], builtin_tostring),
	ValueNativeFunction.new('tonumber', ['thing'], builtin_tonumber),
	ValueNativeFunction.new('typeof', ['it'], builtin_typeof),
	ValueNativeFunction.new('print', ['text'], builtin_print),
	ValueNativeFunction.new('println', ['text'], builtin_println),
	ValueNativeFunction.new('fprint', ['text', 'values'], builtin_fprint),
	ValueNativeFunction.new('fprintln', ['text', 'values'], builtin_fprintln),
	ValueNativeFunction.new('panic', ['text'], builtin_panic),
	ValueNativeFunction.new('gettrace', [], builtin_gettrace),
]

// apply_builtins adds all builtin functions to the given scope.
@[inline]
pub fn apply_builtins(mut scope Scope) {
	for function in builtins {
		scope.new(function.tracer.source, function)
	}
}
