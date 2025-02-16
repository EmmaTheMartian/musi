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

pub const strings_module = [
	ValueNativeFunction.new('repeatstring', ['string', 'count'], strings_repeatstring),
	ValueNativeFunction.new('tochar', ['number'], strings_tochar),
	ValueNativeFunction.new('charat', ['string', 'index'], strings_charat),
	ValueNativeFunction.new('length', ['string'], strings_strlength),
	ValueNativeFunction.new('chars', ['string'], strings_chars),
	ValueNativeFunction.new('findall', ['string', 'substring'], strings_findall),
	ValueNativeFunction.new('replace', ['string', 'substring', 'with'], strings_replace),
	ValueNativeFunction.new('replaceonce', ['string', 'substring', 'with'], strings_replaceonce),
	ValueNativeFunction.new('replaceeach', ['string', 'substring', 'values'], strings_replaceeach),
	ValueNativeFunction.new('replaceeachonce', ['string', 'substring', 'values'], strings_replaceeachonce),
	ValueNativeFunction.new('format', ['string', 'values'], strings_format),
	ValueNativeFunction.new('concat', ['a', 'b'], strings_concat),
	ValueNativeFunction.new('join', ['list', 'delimiter'], strings_join),
]

// apply_strings applies the `strings` module to the given scope.
@[inline]
pub fn apply_strings(mut scope Scope) {
	mut mod := map[string]Value{}
	for func in strings_module {
		mod[func.tracer.source] = func
	}
	scope.new('strings', mod)
}
