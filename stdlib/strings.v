module stdlib

import interpreter { Scope, Value, ValueNativeFunction }
import strings

@[inline]
fn repeatstring(mut scope Scope) Value {
	str := scope.get_fn_arg[string]('string', 'repeatstring')
	count := int(scope.get_fn_arg[f64]('count', 'repeatstring'))
	return strings.repeat_string(str, count)
}

@[inline]
fn tochar(mut scope Scope) Value {
	return u8(scope.get_fn_arg[f64]('number', 'tochar')).ascii_str()
}

@[inline]
fn charat(mut scope Scope) Value {
	str := scope.get_fn_arg[string]('string', 'charat')
	index := int(scope.get_fn_arg[f64]('index', 'charat'))
	unsafe {
		return str[index].ascii_str()
	}
}

@[inline]
fn strlength(mut scope Scope) Value {
	return f64(scope.get_fn_arg[string]('string', 'length').len)
}

@[inline]
fn chars(mut scope Scope) Value {
	return scope.get_fn_arg[string]('string', 'length').runes().map(|it| Value(it.str()))
}

pub const strings_module = {
	'repeatstring': Value(ValueNativeFunction{
		tracer: 'repeatstring'
		args:   ['string', 'count']
		code:   repeatstring
	})
	'tochar':       ValueNativeFunction{
		tracer: 'tochar'
		args:   ['number']
		code:   tochar
	}
	'charat':       ValueNativeFunction{
		tracer: 'charat'
		args:   ['string', 'index']
		code:   charat
	}
	'length':       ValueNativeFunction{
		tracer: 'length'
		args:   ['string']
		code:   strlength
	}
	'chars':        ValueNativeFunction{
		tracer: 'chars'
		args:   ['string']
		code:   chars
	}
}

// apply_lists applies the `strings` module to the given scope.
@[inline]
pub fn apply_strings(mut scope Scope) {
	scope.new('strings', strings_module)
}
