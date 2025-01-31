module stdlib

import interpreter { Scope, Value, ValueNativeFunction }

@[inline]
fn keys(mut scope Scope) Value {
	table := scope.get_fn_arg[map[string]Value]('table', 'keys')
	return table.keys().map(|it| Value(it))
}

@[inline]
fn values(mut scope Scope) Value {
	table := scope.get_fn_arg[map[string]Value]('table', 'values')
	return table.values()
}

@[inline]
fn pairs(mut scope Scope) Value {
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
fn ipairs(mut scope Scope) Value {
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
fn tableset(mut scope Scope) Value {
	mut table := scope.get_fn_arg[map[string]Value]('table', 'set')
	key := scope.get_fn_arg[string]('key', 'set')
	value := scope.get_fn_arg_raw('value', 'set')
	table[key] = value
	return interpreter.null_value
}

@[inline]
fn tableget(mut scope Scope) Value {
	mut table := scope.get_fn_arg[map[string]Value]('table', 'get')
	key := scope.get_fn_arg[string]('key', 'get')
	return table[key] or { scope.throw('failed to index table with key `${key}`') }
}

pub const tables_module = {
	'keys':   Value(ValueNativeFunction{
		tracer: 'keys'
		args:   ['table']
		code:   keys
	})
	'values': ValueNativeFunction{
		tracer: 'values'
		args:   ['table']
		code:   values
	}
	'pairs':  ValueNativeFunction{
		tracer: 'pairs'
		args:   ['table']
		code:   pairs
	}
	'ipairs': ValueNativeFunction{
		tracer: 'ipairs'
		args:   ['table']
		code:   ipairs
	}
	'set':    ValueNativeFunction{
		tracer: 'set'
		args:   ['table', 'key', 'value']
		code:   tableset
	}
	'get':    ValueNativeFunction{
		tracer: 'get'
		args:   ['table', 'key']
		code:   tableget
	}
}

pub fn apply_tables(mut scope Scope) {
	scope.new('tables', tables_module)
}
