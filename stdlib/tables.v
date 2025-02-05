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

pub const tables_module = {
	'keys':   Value(ValueNativeFunction{
		args: ['table']
		code: tables_keys
	})
	'values': ValueNativeFunction{
		args: ['table']
		code: tables_values
	}
	'pairs':  ValueNativeFunction{
		args: ['table']
		code: tables_pairs
	}
	'ipairs': ValueNativeFunction{
		args: ['table']
		code: tables_ipairs
	}
	'set':    ValueNativeFunction{
		args: ['table', 'key', 'value']
		code: tables_set
	}
	'get':    ValueNativeFunction{
		args: ['table', 'key']
		code: tables_get
	}
}

// apply_tables applies the `tables` to the given scope.
pub fn apply_tables(mut scope Scope) {
	scope.new('tables', tables_module)
}
