module stdlib

import interpreter { Scope, Value, ValueNativeFunction }
import strings

@[inline]
fn strings_repeatstring(mut scope Scope) Value {
	str := scope.get_fn_arg[string]('string', 'repeatstring')
	count := int(scope.get_fn_arg[f64]('count', 'repeatstring'))
	return strings.repeat_string(str, count)
}

@[inline]
fn strings_tochar(mut scope Scope) Value {
	return u8(scope.get_fn_arg[f64]('number', 'tochar')).ascii_str()
}

@[inline]
fn strings_charat(mut scope Scope) Value {
	str := scope.get_fn_arg[string]('string', 'charat')
	index := int(scope.get_fn_arg[f64]('index', 'charat'))
	unsafe {
		return str[index].ascii_str()
	}
}

@[inline]
fn strings_strlength(mut scope Scope) Value {
	return f64(scope.get_fn_arg[string]('string', 'length').len)
}

@[inline]
fn strings_chars(mut scope Scope) Value {
	return scope.get_fn_arg[string]('string', 'length').runes().map(|it| Value(it.str()))
}

@[inline]
fn strings_findall(mut scope Scope) Value {
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
fn strings_replace(mut scope Scope) Value {
	str := scope.get_fn_arg[string]('string', 'replace').str()
	substr := scope.get_fn_arg[string]('substring', 'replace')
	with := scope.get_fn_arg[string]('with', 'replace')
	return str.replace(substr, with)
}

@[inline]
fn strings_replaceonce(mut scope Scope) Value {
	str := scope.get_fn_arg[string]('string', 'replaceonce').str()
	substr := scope.get_fn_arg[string]('substring', 'replaceonce')
	with := scope.get_fn_arg[string]('with', 'replaceonce')
	return str.replace_once(substr, with)
}

@[inline]
fn strings_replaceeach(mut scope Scope) Value {
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
fn strings_replaceeachonce(mut scope Scope) Value {
	mut str := scope.get_fn_arg[string]('string', 'replaceeachonce').str()
	substr := scope.get_fn_arg[string]('substring', 'replaceeachonce')
	values := scope.get_fn_arg[[]Value]('values', 'replaceeachonce')
	for value in values {
		str = str.replace_once(substr, value as string)
	}
	return str
}

@[inline]
fn strings_format(mut scope Scope) Value {
	mut str := scope.get_fn_arg[string]('string', 'format').str()
	values := scope.get_fn_arg[[]Value]('values', 'format')
	for value in values {
		str = str.replace_once('%', scope.invoke('tostring', {
			'thing': value
		}) as string)
	}
	return str
}

@[inline]
fn strings_concat(mut scope Scope) Value {
	a := scope.get_fn_arg[string]('a', 'concat').str()
	b := scope.get_fn_arg[string]('b', 'concat').str()
	return a + b
}

@[inline]
fn strings_join(mut scope Scope) Value {
	list := scope.get_fn_arg[[]Value]('list', 'concat')
	delimiter := scope.get_fn_arg[string]('delimiter', 'concat').str()
	return list.map(|it| it.to_string()).join(delimiter)
}

pub const strings_module = {
	'repeatstring':    Value(ValueNativeFunction{
		args: ['string', 'count']
		code: strings_repeatstring
	})
	'tochar':          ValueNativeFunction{
		args: ['number']
		code: strings_tochar
	}
	'charat':          ValueNativeFunction{
		args: ['string', 'index']
		code: strings_charat
	}
	'length':          ValueNativeFunction{
		args: ['string']
		code: strings_strlength
	}
	'chars':           ValueNativeFunction{
		args: ['string']
		code: strings_chars
	}
	'findall':         ValueNativeFunction{
		args: ['string', 'substring']
		code: strings_findall
	}
	'replace':         ValueNativeFunction{
		args: ['string', 'substring', 'with']
		code: strings_replace
	}
	'replaceonce':     ValueNativeFunction{
		args: ['string', 'substring', 'with']
		code: strings_replaceonce
	}
	'replaceeach':     ValueNativeFunction{
		args: ['string', 'substring', 'values']
		code: strings_replaceeach
	}
	'replaceeachonce': ValueNativeFunction{
		args: ['string', 'substring', 'values']
		code: strings_replaceeachonce
	}
	'format':          ValueNativeFunction{
		args: ['string', 'values']
		code: strings_format
	}
	'concat':          ValueNativeFunction{
		args: ['a', 'b']
		code: strings_concat
	}
	'join':            ValueNativeFunction{
		args: ['list', 'delimiter']
		code: strings_join
	}
}

// apply_strings applies the `strings` module to the given scope.
@[inline]
pub fn apply_strings(mut scope Scope) {
	scope.new('strings', strings_module)
}
