module stdlib

import interpreter { IFunctionValue, Scope, Value, ValueFunction, ValueNativeFunction }

@[inline]
fn append(mut scope Scope) Value {
	mut list := scope.get_fn_arg[[]Value]('list', 'append')
	value := scope.get_fn_arg_raw('value', 'append')
	list << value
	return interpreter.null_value
}

@[inline]
fn prepend(mut scope Scope) Value {
	mut list := scope.get_fn_arg[[]Value]('list', 'prepend')
	value := scope.get_fn_arg_raw('value', 'prepend')
	list.prepend(value)
	return interpreter.null_value
}

@[inline]
fn pop(mut scope Scope) Value {
	mut list := scope.get_fn_arg[[]Value]('list', 'pop')
	return list.pop()
}

@[inline]
fn delete(mut scope Scope) Value {
	mut list := scope.get_fn_arg[[]Value]('list', 'delete')
	index := int(scope.get_fn_arg[f64]('index', 'delete'))
	list.delete(index)
	return interpreter.null_value
}

@[inline]
fn clear(mut scope Scope) Value {
	mut list := scope.get_fn_arg[[]Value]('list', 'clear')
	list.clear()
	return interpreter.null_value
}

@[inline]
fn set(mut scope Scope) Value {
	mut list := scope.get_fn_arg[[]Value]('list', 'set')
	index := int(scope.get_fn_arg[f64]('index', 'set'))
	value := scope.get_fn_arg_raw('value', 'set')
	list[index] = value
	return interpreter.null_value
}

@[inline]
fn get(mut scope Scope) Value {
	mut list := scope.get_fn_arg[[]Value]('list', 'get')
	index := int(scope.get_fn_arg[f64]('index', 'get'))
	return list[index]
}

@[inline]
fn each(mut scope Scope) Value {
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
fn range(mut scope Scope) Value {
	from := int(scope.get_fn_arg[f64]('from', 'range'))
	to := int(scope.get_fn_arg[f64]('to', 'range'))
	mut range := []Value{len: to - from, cap: to - from, init: Value{}}
	for x in from .. to {
		range[x - from] = Value(f64(x))
	}
	return range
}

@[inline]
fn listof(mut scope Scope) Value {
	size := int(scope.get_fn_arg[f64]('size', 'listof'))
	of := scope.get_fn_arg_raw('of', 'listof')
	return []Value{len: size, cap: size, init: of}
}

@[inline]
fn filter(mut scope Scope) Value {
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
fn map_(mut scope Scope) Value {
	to_map := scope.get_fn_arg[[]Value]('list', 'map')
	predicate := scope.get_fn_arg_raw('predicate', 'map')
	mut mapped := []Value{}
	for x in to_map {
		mapped << scope.eval_function_list_args(predicate, [x])
	}
	return mapped
}

@[inline]
fn length(mut scope Scope) Value {
	return f64(scope.get_fn_arg[[]Value]('list', 'length').len)
}

pub const lists_module = {
	'append':  Value(ValueNativeFunction{
		tracer: 'append'
		args:   ['list', 'value']
		code:   append
	})
	'prepend': ValueNativeFunction{
		tracer: 'prepend'
		args:   ['list', 'value']
		code:   prepend
	}
	'pop':     ValueNativeFunction{
		tracer: 'pop'
		args:   ['list']
		code:   pop
	}
	'delete':  ValueNativeFunction{
		tracer: 'delete'
		args:   ['list', 'index']
		code:   delete
	}
	'clear':   ValueNativeFunction{
		tracer: 'clear'
		args:   ['list']
		code:   clear
	}
	'set':     ValueNativeFunction{
		tracer: 'set'
		args:   ['list', 'index', 'value']
		code:   set
	}
	'get':     ValueNativeFunction{
		tracer: 'get'
		args:   ['list', 'index']
		code:   get
	}
	'each':    ValueNativeFunction{
		tracer: 'each'
		args:   ['list', 'action']
		code:   each
	}
	'range':   ValueNativeFunction{
		tracer: 'range'
		args:   ['from', 'to']
		code:   range
	}
	'listof':  ValueNativeFunction{
		tracer: 'listof'
		args:   ['size', 'of']
		code:   listof
	}
	'filter':  ValueNativeFunction{
		tracer: 'filter'
		args:   ['list', 'predicate']
		code:   filter
	}
	'map':     ValueNativeFunction{
		tracer: 'map'
		args:   ['list', 'predicate']
		code:   map_
	}
	'length':  ValueNativeFunction{
		tracer: 'length'
		args:   ['list']
		code:   length
	}
}

// apply_lists applies the `lists` module to the given scope.
@[inline]
pub fn apply_lists(mut scope Scope) {
	scope.new('lists', lists_module)
}
