module stdlib

import interpreter { Scope, Value, ValueNativeFunction }

@[inline]
fn macros_quote(mut scope Scope) Value {
	tokens := scope.get_fn_arg[[]Value]('tokens', 'quote').map(|it| it as map[string]Value)
	mut processed := [Value({
		'kind':  Value('literal')
		'value': '['
	})]
	for token in tokens {
		processed << Value({
			'kind':  Value('literal')
			'value': '{'
		})
		processed << Value({
			'kind':  Value('id')
			'value': 'kind'
		})
		processed << Value({
			'kind':  Value('operator')
			'value': '='
		})
		processed << Value({
			'kind':  Value('str')
			'value': token['kind'] or { scope.throw('quote: token had no `kind`') }
		})
		processed << Value({
			'kind':  Value('id')
			'value': 'value'
		})
		processed << Value({
			'kind':  Value('operator')
			'value': '='
		})
		processed << Value({
			'kind':  Value('str')
			'value': token['value'] or { scope.throw('quote: token had no `value`') }
		})
		processed << Value({
			'kind':  Value('literal')
			'value': '}'
		})
		processed << Value({
			'kind':  Value('literal')
			'value': ','
		})
	}
	processed << Value({
		'kind':  Value('literal')
		'value': ']'
	})
	return processed
}

@[inline]
fn macros_lambda(mut scope Scope) Value {
	tokens := scope.get_fn_arg[[]Value]('tokens', 'quote')

	mut processed := [Value({
		'kind':  Value('keyword')
		'value': 'fn'
	})]

	mut found_pipe := false
	for token in tokens {
		if !found_pipe && token is map[string]Value
			&& token['kind'] or {
			scope.throw('lambda: token had no `kind`')
		} == Value('operator')
			&& token['value'] or { scope.throw('lambda: token had no `value`') } == Value('->') {
			found_pipe = true
			processed << Value({
				'kind':  Value('keyword')
				'value': 'do'
			})
			processed << Value({
				'kind':  Value('keyword')
				'value': 'return'
			})
			continue
		}
		processed << token
	}

	processed << Value({
		'kind':  Value('keyword')
		'value': 'end'
	})

	return processed
}

pub const macros_module = [
	ValueNativeFunction.new_macro('quote', ['tokens'], macros_quote),
	ValueNativeFunction.new_macro('lambda', ['tokens'], macros_lambda),
]

// apply_macros applies the `macros` module to the given scope.
@[inline]
pub fn apply_macros(mut scope Scope) {
	mut mod := map[string]Value{}
	for func in macros_module {
		mod[func.tracer.source] = func
	}
	scope.new('macros', mod)
}
