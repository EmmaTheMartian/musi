module stdlib

import interpreter { Scope, Value, ValueNativeFunction }
import strings

@[inline]
pub fn repeatstring(mut scope Scope) Value {
	str := scope.get_fn_arg[string]('string', 'repeatstring')
	count := int(scope.get_fn_arg[f64]('count', 'repeatstring'))
	return Value(strings.repeat_string(str, count))
}

pub const strings_module = {
	'repeatstring': Value(ValueNativeFunction{
		tracer: 'repeatstring'
		args:   ['string', 'count']
		code:   repeatstring
	})
}

// apply_lists applies the `strings` module to the given scope.
@[inline]
pub fn apply_strings(mut scope Scope) {
	scope.new('strings', strings_module)
}
