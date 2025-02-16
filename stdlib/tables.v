module stdlib

import interpreter { Scope, Value, ValueNativeFunction }

@[inline]
fn tables_keys(mut scope Scope) Value {
	table := scope.get_fn_arg[map[string]Value]('table', 'keys')
	return table.keys().map(|it| Value(it))
}

@[inline]
fn tables_values(mut scope Scope) Value {
	table := scope.get_fn_arg[map[string]Value]('table', 'values')
	return table.values()
}

@[inline]
fn tables_pairs(mut scope Scope) Value {
	table := scope.get_fn_arg[map[string]Value]('table', 'pairs')
	mut pairs := []Value{}
	for key, value in table {
		pairs << {
			'key':   Value(key)
			'value': value
		}
	}
	return pairs
}

@[inline]
fn tables_ipairs(mut scope Scope) Value {
	table := scope.get_fn_arg[map[string]Value]('table', 'pairs')
	mut pairs := []Value{}
	mut i := 0
	for key, value in table {
		pairs << {
			'index': Value(f64(i))
			'key':   Value(key)
			'value': value
		}
		i++
	}
	return pairs
}

@[inline]
fn tables_set(mut scope Scope) Value {
	mut table := scope.get_fn_arg_ptr[map[string]Value]('table', 'set')
	key := scope.get_fn_arg[string]('key', 'set')
	value := scope.get_fn_arg_raw('value', 'set')
	unsafe {
		table[key] = value
	}
	return interpreter.null_value
}

@[inline]
fn tables_get(mut scope Scope) Value {
	mut table := scope.get_fn_arg[map[string]Value]('table', 'get')
	key := scope.get_fn_arg[string]('key', 'get')
	return table[key] or { scope.throw('failed to index table with key `${key}`') }
}

pub const tables_module = [
	ValueNativeFunction.new('keys', ['table'], tables_keys),
	ValueNativeFunction.new('values', ['table'], tables_values),
	ValueNativeFunction.new('pairs', ['table'], tables_pairs),
	ValueNativeFunction.new('ipairs', ['table'], tables_ipairs),
	ValueNativeFunction.new('set', ['table', 'key', 'value'], tables_set),
	ValueNativeFunction.new('get', ['table', 'key'], tables_get),
]

// apply_tables applies the `tables` to the given scope.
pub fn apply_tables(mut scope Scope) {
	mut mod := map[string]Value{}
	for func in tables_module {
		mod[func.tracer.source] = func
	}
	scope.new('tables', mod)
}
