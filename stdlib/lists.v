module stdlib

import interpreter { IFunctionValue, Scope, Value, ValueFunction, ValueNativeFunction }

@[inline]
fn lists_append(mut scope Scope) Value {
	mut list := scope.get_fn_arg_ptr[[]Value]('list', 'append')
	value := scope.get_fn_arg_raw('value', 'append')
	list << value
	return interpreter.null_value
}

@[inline]
fn lists_prepend(mut scope Scope) Value {
	mut list := scope.get_fn_arg_ptr[[]Value]('list', 'prepend')
	value := scope.get_fn_arg_raw('value', 'prepend')
	list.prepend(value)
	return interpreter.null_value
}

@[inline]
fn lists_pop(mut scope Scope) Value {
	mut list := scope.get_fn_arg_ptr[[]Value]('list', 'pop')
	if list.len == 0 {
		scope.throw('lists.pop: cannot invoke pop on empty list')
	}
	return list.pop()
}

@[inline]
fn lists_delete(mut scope Scope) Value {
	mut list := scope.get_fn_arg_ptr[[]Value]('list', 'delete')
	index := int(scope.get_fn_arg[f64]('index', 'delete'))
	list.delete(index)
	return interpreter.null_value
}

@[inline]
fn lists_clear(mut scope Scope) Value {
	mut list := scope.get_fn_arg_ptr[[]Value]('list', 'clear')
	list.clear()
	return interpreter.null_value
}

@[inline]
fn lists_set(mut scope Scope) Value {
	mut list := scope.get_fn_arg_ptr[[]Value]('list', 'set')
	index := int(scope.get_fn_arg[f64]('index', 'set'))
	value := scope.get_fn_arg_raw('value', 'set')
	unsafe {
		list[index] = value
	}
	return interpreter.null_value
}

@[inline]
fn lists_get(mut scope Scope) Value {
	mut list := scope.get_fn_arg[[]Value]('list', 'get')
	index := int(scope.get_fn_arg[f64]('index', 'get'))
	return list[index]
}

@[inline]
fn lists_each(mut scope Scope) Value {
	list := scope.get_fn_arg[[]Value]('list', 'each')
	action := scope.get_fn_arg_raw('action', 'each')

	func := if action is ValueFunction {
		IFunctionValue(action)
	} else if action is ValueNativeFunction {
		IFunctionValue(action)
	} else {
		scope.throw('each: action must be a function')
	}

	for value in list {
		func.run(mut scope, {
			func.args[0]: value
		})
	}

	return interpreter.null_value
}

@[inline]
fn lists_tryeach(mut scope Scope) Value {
	list := scope.get_fn_arg[[]Value]('list', 'tryeach')
	action := scope.get_fn_arg_raw('action', 'tryeach')

	func := if action is ValueFunction {
		IFunctionValue(action)
	} else if action is ValueNativeFunction {
		IFunctionValue(action)
	} else {
		scope.throw('each: action must be a function')
	}

	mut result := interpreter.null_value
	for value in list {
		result = func.run(mut scope, {
			func.args[0]: value
		})
		if result is bool && result == false {
			break
		}
	}

	return interpreter.null_value
}

@[inline]
fn lists_ieach(mut scope Scope) Value {
	list := scope.get_fn_arg[[]Value]('list', 'ieach')
	action := scope.get_fn_arg_raw('action', 'ieach')

	func := if action is ValueFunction {
		IFunctionValue(action)
	} else if action is ValueNativeFunction {
		IFunctionValue(action)
	} else {
		scope.throw('ieach: action must be a function')
	}

	for index, value in list {
		func.run(mut scope, {
			func.args[0]: f64(index)
			func.args[1]: value
		})
	}

	return interpreter.null_value
}

@[inline]
fn lists_tryieach(mut scope Scope) Value {
	list := scope.get_fn_arg[[]Value]('list', 'tryieach')
	action := scope.get_fn_arg_raw('action', 'tryieach')

	func := if action is ValueFunction {
		IFunctionValue(action)
	} else if action is ValueNativeFunction {
		IFunctionValue(action)
	} else {
		scope.throw('tryieach: action must be a function')
	}

	mut result := interpreter.null_value
	for index, value in list {
		result = func.run(mut scope, {
			func.args[0]: f64(index)
			func.args[1]: value
		})
		if result is bool && result == false {
			break
		}
	}

	return interpreter.null_value
}

@[inline]
fn lists_range(mut scope Scope) Value {
	from := int(scope.get_fn_arg[f64]('from', 'range'))
	to := int(scope.get_fn_arg[f64]('to', 'range'))
	mut range := []Value{len: to - from, cap: to - from, init: Value{}}
	for x in from .. to {
		range[x - from] = Value(f64(x))
	}
	return range
}

@[inline]
fn lists_listof(mut scope Scope) Value {
	size := int(scope.get_fn_arg[f64]('size', 'listof'))
	of := scope.get_fn_arg_raw('of', 'listof')
	return []Value{len: size, cap: size, init: of}
}

@[inline]
fn lists_filter(mut scope Scope) Value {
	to_filter := scope.get_fn_arg[[]Value]('list', 'filter')
	predicate := scope.get_fn_arg_raw('predicate', 'filter')
	mut filtered := []Value{}
	for x in to_filter {
		if scope.eval_function_list_args(predicate, [x]) == Value(true) {
			filtered << x
		}
	}
	return filtered
}

@[inline]
fn lists_map(mut scope Scope) Value {
	to_map := scope.get_fn_arg[[]Value]('list', 'map')
	predicate := scope.get_fn_arg_raw('predicate', 'map')
	mut mapped := []Value{}
	for x in to_map {
		mapped << scope.eval_function_list_args(predicate, [x])
	}
	return mapped
}

@[inline]
fn lists_length(mut scope Scope) Value {
	return f64(scope.get_fn_arg[[]Value]('list', 'length').len)
}

@[inline]
fn lists_reversed(mut scope Scope) Value {
	return scope.get_fn_arg[[]Value]('list', 'reversed').reverse()
}

@[inline]
fn lists_index(mut scope Scope) Value {
	return f64(scope.get_fn_arg[[]Value]('list', 'index').index(scope.get_fn_arg_raw('it',
		'index')))
}

@[inline]
fn lists_contains(mut scope Scope) Value {
	return scope.get_fn_arg[[]Value]('list', 'index').contains(scope.get_fn_arg_raw('it',
		'index'))
}

pub const lists_module = [
	ValueNativeFunction.new('append', ['list', 'value'], lists_append),
	ValueNativeFunction.new('prepend', ['list', 'value'], lists_prepend),
	ValueNativeFunction.new('pop', ['list'], lists_pop),
	ValueNativeFunction.new('delete', ['list', 'index'], lists_delete),
	ValueNativeFunction.new('clear', ['list'], lists_clear),
	ValueNativeFunction.new('set', ['list', 'index', 'value'], lists_set),
	ValueNativeFunction.new('get', ['list', 'index'], lists_get),
	ValueNativeFunction.new('each', ['list', 'action'], lists_each),
	ValueNativeFunction.new('tryeach', ['list', 'action'], lists_tryeach),
	ValueNativeFunction.new('ieach', ['list', 'action'], lists_ieach),
	ValueNativeFunction.new('tryieach', ['list', 'action'], lists_tryieach),
	ValueNativeFunction.new('range', ['from', 'to'], lists_range),
	ValueNativeFunction.new('listof', ['size', 'of'], lists_listof),
	ValueNativeFunction.new('filter', ['list', 'predicate'], lists_filter),
	ValueNativeFunction.new('map', ['list', 'predicate'], lists_map),
	ValueNativeFunction.new('length', ['list'], lists_length),
	ValueNativeFunction.new('revsersed', ['list'], lists_reversed),
	ValueNativeFunction.new('index', ['list', 'it'], lists_index),
	ValueNativeFunction.new('contains', ['list', 'it'], lists_contains),
]

// apply_lists applies the `lists` module to the given scope.
@[inline]
pub fn apply_lists(mut scope Scope) {
	mut mod := map[string]Value{}
	for func in lists_module {
		mod[func.tracer.source] = func
	}
	scope.new('lists', mod)
}
