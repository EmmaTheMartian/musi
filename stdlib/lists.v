module stdlib

import interpreter { IFunctionValue, Scope, Value, ValueFunction, ValueNativeFunction }

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
	return Value(range)
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
	return Value(filtered)
}

@[inline]
fn map_(mut scope Scope) Value {
	to_map := scope.get_fn_arg[[]Value]('list', 'map')
	predicate := scope.get_fn_arg_raw('predicate', 'map')
	mut mapped := []Value{}
	for x in to_map {
		mapped << scope.eval_function_list_args(predicate, [x])
	}
	return Value(mapped)
}

pub const lists_module = {
	'each':   Value(ValueNativeFunction{
		tracer: 'each'
		args:   ['list', 'action']
		code:   each
	})
	'range':  ValueNativeFunction{
		tracer: 'range'
		args:   ['from', 'to']
		code:   range
	}
	'filter': ValueNativeFunction{
		tracer: 'filter'
		args:   ['list', 'predicate']
		code:   filter
	}
	'map':    ValueNativeFunction{
		tracer: 'map'
		args:   ['list', 'predicate']
		code:   map_
	}
}

// apply_lists applies the `lists` module to the given scope.
@[inline]
pub fn apply_lists(mut scope Scope) {
	scope.new('lists', lists_module)
}
