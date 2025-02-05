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
		}, 'action')
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
		}, 'action')
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
		if scope.eval_function_list_args(predicate, [x], 'predicate') == Value(true) {
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
		mapped << scope.eval_function_list_args(predicate, [x], 'predicate')
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

pub const lists_module = {
	'append':    Value(ValueNativeFunction{
		args: ['list', 'value']
		code: lists_append
	})
	'prepend':   ValueNativeFunction{
		args: ['list', 'value']
		code: lists_prepend
	}
	'pop':       ValueNativeFunction{
		args: ['list']
		code: lists_pop
	}
	'delete':    ValueNativeFunction{
		args: ['list', 'index']
		code: lists_delete
	}
	'clear':     ValueNativeFunction{
		args: ['list']
		code: lists_clear
	}
	'set':       ValueNativeFunction{
		args: ['list', 'index', 'value']
		code: lists_set
	}
	'get':       ValueNativeFunction{
		args: ['list', 'index']
		code: lists_get
	}
	'each':      ValueNativeFunction{
		args: ['list', 'action']
		code: lists_each
	}
	'ieach':     ValueNativeFunction{
		args: ['list', 'action']
		code: lists_ieach
	}
	'range':     ValueNativeFunction{
		args: ['from', 'to']
		code: lists_range
	}
	'listof':    ValueNativeFunction{
		args: ['size', 'of']
		code: lists_listof
	}
	'filter':    ValueNativeFunction{
		args: ['list', 'predicate']
		code: lists_filter
	}
	'map':       ValueNativeFunction{
		args: ['list', 'predicate']
		code: lists_map
	}
	'length':    ValueNativeFunction{
		args: ['list']
		code: lists_length
	}
	'revsersed': ValueNativeFunction{
		args: ['list']
		code: lists_reversed
	}
	'index':     ValueNativeFunction{
		args: ['list', 'it']
		code: lists_index
	}
	'contains':  ValueNativeFunction{
		args: ['list', 'it']
		code: lists_contains
	}
}

// apply_lists applies the `lists` module to the given scope.
@[inline]
pub fn apply_lists(mut scope Scope) {
	scope.new('lists', lists_module)
}
