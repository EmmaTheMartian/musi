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

@[inline]
fn findall(mut scope Scope) Value {
	str := scope.get_fn_arg[string]('string', 'findall')
	substr := scope.get_fn_arg[string]('substring', 'findall')

	mut all := []Value{}
	mut i := 0
	for i <= str.len {
		found := str.index_after(substr, i)
		if found != -1 {
			all << f64(found)
			// we increment here to ensure we don't get matches in matches (and t reduce the number of .index_after calls)
			i += found + substr.len
			continue
		}
		i++
	}

	return all
}

@[inline]
pub fn replace(mut scope Scope) Value {
	str := scope.get_fn_arg[string]('string', 'replace').str()
	substr := scope.get_fn_arg[string]('substring', 'replace')
	return str.replace(str, substr)
}

@[inline]
pub fn replaceonce(mut scope Scope) Value {
	str := scope.get_fn_arg[string]('string', 'replaceonce').str()
	substr := scope.get_fn_arg[string]('substring', 'replaceonce')
	return str.replace_once(str, substr)
}

@[inline]
pub fn replaceeach(mut scope Scope) Value {
	str := scope.get_fn_arg[string]('string', 'replaceeach').str()
	substr := scope.get_fn_arg[string]('substring', 'replaceeach')
	values := scope.get_fn_arg[[]Value]('values', 'replaceeach')
	mut replacements := []string{len: values.len * 2, cap: values.len * 2}
	for index, value in values {
		replacements[index * 2] = substr
		replacements[index * 2 + 1] = value as string
	}
	return str.replace_each(replacements)
}

@[inline]
pub fn replaceeachonce(mut scope Scope) Value {
	mut str := scope.get_fn_arg[string]('string', 'replaceeachonce').str()
	substr := scope.get_fn_arg[string]('substring', 'replaceeachonce')
	values := scope.get_fn_arg[[]Value]('values', 'replaceeachonce')
	for value in values {
		str = str.replace_once(substr, value as string)
	}
	return str
}

@[inline]
pub fn format(mut scope Scope) Value {
	mut str := scope.get_fn_arg[string]('string', 'format').str()
	values := scope.get_fn_arg[[]Value]('values', 'format')
	for value in values {
		str = str.replace_once('%', scope.invoke('tostring', {'thing': value}) as string)
	}
	return str
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
	'findall':      ValueNativeFunction{
		tracer: 'findall'
		args:   ['string', 'substring']
		code:   findall
	}
	'replace':       ValueNativeFunction{
		tracer: 'replace'
		args:   ['string', 'substring']
		code:   replace
	}
	'replaceonce':       ValueNativeFunction{
		tracer: 'replaceonce'
		args:   ['string', 'substring']
		code:   replaceonce
	}
	'replaceeach':       ValueNativeFunction{
		tracer: 'replaceeach'
		args:   ['string', 'substring', 'values']
		code:   replaceeach
	}
	'replaceeachonce':       ValueNativeFunction{
		tracer: 'replaceeachonce'
		args:   ['string', 'substring', 'values']
		code:   replaceeachonce
	}
	'format':       ValueNativeFunction{
		tracer: 'format'
		args:   ['string', 'values']
		code:   format
	}
}

// apply_strings applies the `strings` module to the given scope.
@[inline]
pub fn apply_strings(mut scope Scope) {
	scope.new('strings', strings_module)
}
