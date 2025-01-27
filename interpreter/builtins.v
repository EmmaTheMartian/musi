module interpreter

pub fn apply_builtins(mut scope Scope) {
	// modules

	scope.new('import', ValueNativeFunction{
		tracer: 'import'
		args:   ['module']
		code:   fn (mut scope Scope) Value {
			return scope.import(get_fn_arg[string](scope, 'module', 'import'))
		}
	})

	// casting

	scope.new('tostring', ValueNativeFunction{
		tracer: 'tostring'
		args:   ['thing']
		code:   fn (mut scope Scope) Value {
			thing := get_fn_arg_raw(scope, 'thing', 'tostring')
			match thing {
				string {
					return Value(thing)
				}
				f64 {
					return Value(thing.str())
				}
				bool {
					return Value(thing.str())
				}
				ValueFunction {
					return Value(thing.tracer)
				}
				ValueNativeFunction {
					return Value(thing.tracer)
				}
				[]Value {
					return Value('list')
				}
				map[string]Value {
					return Value('table')
				}
				ValueNull {
					return Value('null')
				}
			}
		}
	})

	scope.new('tonumber', ValueNativeFunction{
		tracer: 'tostring'
		args:   ['thing']
		code:   fn (mut scope Scope) Value {
			thing := get_fn_arg_raw(scope, 'thing', 'tonumber')
			match thing {
				string {
					return Value(thing.f64())
				}
				f64 {
					return Value(thing)
				}
				else {
					scope.throw('tonumber: cannot cast ${typeof(thing).name} to number')
				}
			}
		}
	})

	// input/output

	scope.new('print', ValueNativeFunction{
		tracer: 'print'
		args:   ['text']
		code:   fn (mut scope Scope) Value {
			text := get_fn_arg_raw(scope, 'text', 'print')
			print(scope.invoke('tostring', {
				'thing': text
			}) as string)
			return null_value
		}
	})

	scope.new('println', ValueNativeFunction{
		tracer: 'println'
		args:   ['text']
		code:   fn (mut scope Scope) Value {
			text := get_fn_arg_raw(scope, 'text', 'println')
			println(scope.invoke('tostring', {
				'thing': text
			}) as string)
			return null_value
		}
	})

	scope.new('panic', ValueNativeFunction{
		tracer: 'panic'
		args:   ['text']
		code:   fn (mut scope Scope) Value {
			text := get_fn_arg_raw(scope, 'text', 'panic')
			scope.throw(scope.invoke('tostring', {
				'thing': text
			}) as string)
			return null_value
		}
	})

	// loops and generators

	scope.new('each', ValueNativeFunction{
		tracer: 'each'
		args:   ['list', 'action']
		code:   fn (mut scope Scope) Value {
			list := get_fn_arg[[]Value](scope, 'list', 'each')
			action := get_fn_arg_raw(scope, 'action', 'each')

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

			return null_value
		}
	})

	scope.new('range', ValueNativeFunction{
		tracer: 'range'
		args:   ['from', 'to']
		code:   fn (mut scope Scope) Value {
			from := int(get_fn_arg[f64](scope, 'from', 'range'))
			to := int(get_fn_arg[f64](scope, 'to', 'range'))
			mut range := []Value{len: to - from, cap: to - from, init: Value{}}
			for x in from .. to {
				range[x - from] = Value(f64(x))
			}
			return Value(range)
		}
	})

	scope.new('filter', ValueNativeFunction{
		tracer: 'filter'
		args:   ['list', 'predicate']
		code:   fn (mut scope Scope) Value {
			to_filter := get_fn_arg[[]Value](scope, 'list', 'filter')
			predicate := get_fn_arg_raw(scope, 'predicate', 'filter')
			mut filtered := []Value{}
			for x in to_filter {
				if scope.eval_function_list_args(predicate, [x]) == Value(true) {
					filtered << x
				}
			}
			return Value(filtered)
		}
	})

	// comparison

	add_comparison_operator(mut scope, 'equals', |a, b| a == b)
	add_comparison_operator(mut scope, 'notequals', |a, b| a != b)
	add_numeric_comparison_operator(mut scope, 'gt', |a, b| a > b)
	add_numeric_comparison_operator(mut scope, 'lt', |a, b| a < b)
	add_numeric_comparison_operator(mut scope, 'gteq', |a, b| a >= b)
	add_numeric_comparison_operator(mut scope, 'lteq', |a, b| a <= b)
	add_bool_comparison_operator(mut scope, 'or', |a, b| a || b)
	add_bool_comparison_operator(mut scope, 'and', |a, b| a && b)

	// math

	scope.new('add', ValueNativeFunction{
		tracer: 'add'
		args:   ['a', 'b']
		code:   fn (mut scope Scope) Value {
			a := get_fn_arg[f64](scope, 'a', 'add')
			b := get_fn_arg[f64](scope, 'b', 'add')
			return Value(a + b)
		}
	})

	scope.new('sub', ValueNativeFunction{
		tracer: 'sub'
		args:   ['a', 'b']
		code:   fn (mut scope Scope) Value {
			a := get_fn_arg[f64](scope, 'a', 'sub')
			b := get_fn_arg[f64](scope, 'b', 'sub')
			return Value(a - b)
		}
	})

	scope.new('mul', ValueNativeFunction{
		tracer: 'mul'
		args:   ['a', 'b']
		code:   fn (mut scope Scope) Value {
			a := get_fn_arg[f64](scope, 'a', 'mul')
			b := get_fn_arg[f64](scope, 'b', 'mul')
			return Value(a * b)
		}
	})

	scope.new('div', ValueNativeFunction{
		tracer: 'div'
		args:   ['a', 'b']
		code:   fn (mut scope Scope) Value {
			a := get_fn_arg[f64](scope, 'a', 'div')
			b := get_fn_arg[f64](scope, 'b', 'div')
			return Value(a / b)
		}
	})

	scope.new('mod', ValueNativeFunction{
		tracer: 'mod'
		args:   ['a', 'b']
		code:   fn (mut scope Scope) Value {
			a := int(get_fn_arg[f64](scope, 'a', 'mod'))
			b := int(get_fn_arg[f64](scope, 'b', 'mod'))
			return Value(f64(a % b))
		}
	})
}
