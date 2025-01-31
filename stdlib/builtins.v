module stdlib

import interpreter { Scope, Value, ValueFunction, ValueNativeFunction, ValueNull }

@[inline]
fn import_(mut scope Scope) Value {
	return scope.import(scope.get_fn_arg[string]('module', 'import'))
}

@[inline]
fn tostring(mut scope Scope) Value {
	thing := scope.get_fn_arg_raw('thing', 'tostring')
	match thing {
		string {
			return thing
		}
		f64 {
			return thing.str()
		}
		bool {
			return thing.str()
		}
		ValueFunction {
			return thing.tracer
		}
		ValueNativeFunction {
			return thing.tracer
		}
		[]Value {
			return thing.str()
			// return Value('list')
		}
		map[string]Value {
			return thing.str()
			// return Value('table')
		}
		ValueNull {
			return 'null'
		}
		voidptr { return 'voidptr' }
	}
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
fn panic_(mut scope Scope) Value {
	text := scope.get_fn_arg_raw('text', 'panic')
	scope.throw(scope.invoke('tostring', {
		'thing': text
	}) as string)
	return interpreter.null_value
}

pub const builtins = {
	'import':   Value(ValueNativeFunction{
		tracer: 'import'
		args:   ['module']
		code:   import_
	})
	'tostring': ValueNativeFunction{
		tracer: 'tostring'
		args:   ['thing']
		code:   tostring
	}
	'tonumber': ValueNativeFunction{
		tracer: 'tostring'
		args:   ['thing']
		code:   tonumber
	}
	'typeof':   ValueNativeFunction{
		tracer: 'typeof'
		args:   ['it']
		code:   typeof_
	}
	'print':    ValueNativeFunction{
		tracer: 'print'
		args:   ['text']
		code:   print_
	}
	'println':  ValueNativeFunction{
		tracer: 'println'
		args:   ['text']
		code:   println_
	}
	'panic':    ValueNativeFunction{
		tracer: 'panic'
		args:   ['text']
		code:   panic_
	}
}

// apply_builtins adds all builtin functions to the given scope.
@[inline]
pub fn apply_builtins(mut scope Scope) {
	for name, value in builtins {
		scope.new(name, value)
	}
}
