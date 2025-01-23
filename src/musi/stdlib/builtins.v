module stdlib

import musi.interpreter { Scope, Value }
import musi.lib

pub fn apply_builtins(mut scope Scope) {
	// casting

	scope.new('tostring', interpreter.ValueNativeFunction{
		tracer: 'tostring',
		args: ['thing'],
		code: fn (mut scope Scope) Value {
			thing := scope.get_own('thing') or {
				panic('musi: tostring: no argument provided')
			}
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
				interpreter.ValueFunction {
					return Value(thing.tracer)
				}
				interpreter.ValueNativeFunction {
					return Value(thing.tracer)
				}
				[]Value {
					return Value('list')
				}
			}
		}
	})

	scope.new('tonumber', interpreter.ValueNativeFunction{
		tracer: 'tostring',
		args: ['thing'],
		code: fn (mut scope Scope) Value {
			thing := lib.get_fn_arg_raw(scope, 'thing', 'tonumber')
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

	scope.new('print', interpreter.ValueNativeFunction{
		tracer: 'print',
		args: ['text']
		code: fn (mut scope Scope) Value {
			text := lib.get_fn_arg_raw(scope, 'text', 'print')
			print(scope.invoke('tostring', {'thing': text}) as string)
			return interpreter.empty
		}
	})

	scope.new('println', interpreter.ValueNativeFunction{
		tracer: 'println',
		args: ['text']
		code: fn (mut scope Scope) Value {
			text := lib.get_fn_arg_raw(scope, 'text', 'println')
			println(scope.invoke('tostring', {'thing': text}) as string)
			return interpreter.empty
		}
	})

	scope.new('panic', interpreter.ValueNativeFunction{
		tracer: 'panic',
		args: ['text']
		code: fn (mut scope Scope) Value {
			text := lib.get_fn_arg_raw(scope, 'text', 'panic')
			scope.throw(scope.invoke('tostring', {'thing': text}) as string)
			return interpreter.empty
		}
	})

	// loops and generators

	scope.new('each', interpreter.ValueNativeFunction{
		tracer: 'each',
		args: ['list', 'action']
		code: fn (mut scope Scope) Value {
			list := lib.get_fn_arg[[]interpreter.Value](scope, 'list', 'each')
			action := lib.get_fn_arg_raw(scope, 'action', 'each')

			func := if action is interpreter.ValueFunction {
				interpreter.IFunctionValue(action)
			} else if action is interpreter.ValueNativeFunction {
				interpreter.IFunctionValue(action)
			} else {
				panic('musi: each: action must be a function')
			}

			for value in list {
				func.run(mut scope, {func.args[0]: value})
			}

			return interpreter.empty
		}
	})

	scope.new('range', interpreter.ValueNativeFunction{
		tracer: 'range'
		args: ['from', 'to']
		code: fn (mut scope Scope) Value {
			from := int(lib.get_fn_arg[f64](scope, 'from', 'range'))
			to := int(lib.get_fn_arg[f64](scope, 'to', 'range'))
			mut range := []Value{len: to-from, cap: to-from, init: Value{}}
			for x in from..to {
				range[x - from] = Value(f64(x))
			}
			return Value(range)
		}
	})

	scope.new('filter', interpreter.ValueNativeFunction{
		tracer: 'filter'
		args: ['list', 'predicate']
		code: fn (mut scope Scope) Value {
			to_filter := lib.get_fn_arg[[]Value](scope, 'list', 'filter')
			predicate := lib.get_fn_arg_raw(scope, 'predicate', 'filter')
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

	lib.add_comparison_operator(mut scope, 'equals', |a, b| a == b)
	lib.add_comparison_operator(mut scope, 'not-equals', |a, b| a != b)
	lib.add_numeric_comparison_operator(mut scope, 'gt', |a, b| a > b)
	lib.add_numeric_comparison_operator(mut scope, 'lt', |a, b| a < b)
	lib.add_numeric_comparison_operator(mut scope, 'gteq', |a, b| a >= b)
	lib.add_numeric_comparison_operator(mut scope, 'lteq', |a, b| a <= b)

	// math

	scope.new('add', interpreter.ValueNativeFunction{
		tracer: 'add',
		args: ['a', 'b'],
		code: fn (mut scope Scope) Value {
			a := lib.get_fn_arg[f64](scope, 'a', 'add')
			b := lib.get_fn_arg[f64](scope, 'b', 'add')
			return Value(a + b)
		}
	})

	scope.new('sub', interpreter.ValueNativeFunction{
		tracer: 'sub',
		args: ['a', 'b'],
		code: fn (mut scope Scope) Value {
			a := lib.get_fn_arg[f64](scope, 'a', 'sub')
			b := lib.get_fn_arg[f64](scope, 'b', 'sub')
			return Value(a - b)
		}
	})

	scope.new('mul', interpreter.ValueNativeFunction{
		tracer: 'mul',
		args: ['a', 'b'],
		code: fn (mut scope Scope) Value {
			a := lib.get_fn_arg[f64](scope, 'a', 'mul')
			b := lib.get_fn_arg[f64](scope, 'b', 'mul')
			return Value(a * b)
		}
	})

	scope.new('div', interpreter.ValueNativeFunction{
		tracer: 'div',
		args: ['a', 'b'],
		code: fn (mut scope Scope) Value {
			a := lib.get_fn_arg[f64](scope, 'a', 'div')
			b := lib.get_fn_arg[f64](scope, 'b', 'div')
			return Value(a / b)
		}
	})

	scope.new('mod', interpreter.ValueNativeFunction{
		tracer: 'mod',
		args: ['a', 'b'],
		code: fn (mut scope Scope) Value {
			a := int(lib.get_fn_arg[f64](scope, 'a', 'mod'))
			b := int(lib.get_fn_arg[f64](scope, 'b', 'mod'))
			return Value(f64(a % b))
		}
	})
}
