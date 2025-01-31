module stdlib

import interpreter { Scope, Value, ValueNativeFunction }

@[inline]
fn keys(mut scope Scope) Value {
	table := scope.get_fn_arg[map[string]Value]('table', 'keys')
	return Value(table.keys().map(|it| Value(it)))
}

@[inline]
fn values(mut scope Scope) Value {
	table := scope.get_fn_arg[map[string]Value]('table', 'values')
	return Value(table.values())
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
	return Value(pairs)
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
	return Value(pairs)
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
}

pub fn apply_tables(mut scope Scope) {
	scope.new('tables', tables_module)
}
