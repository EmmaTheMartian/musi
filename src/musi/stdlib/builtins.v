module stdlib

import musi.interpreter { Scope, Value }
import musi.lib

// apply_math applies all mathematic builtins:
// add, sub, div, mul, mod
pub fn apply_math(mut scope Scope) {
	scope.new('add', interpreter.ValueNativeFunction{
		tracer: 'add',
		args: ['a', 'b'],
		code: fn (mut scope Scope) Value {
			a := lib.get_fn_arg[f64](scope, 'a', 'add')
			b := lib.get_fn_arg[f64](scope, 'b', 'add')
			return Value(a + b)
		}
	})
}

pub fn apply_all(mut scope Scope) {
	apply_math(mut scope)

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

	scope.new('print', interpreter.ValueNativeFunction{
		tracer: 'print',
		args: ['text']
		code: fn (mut scope Scope) Value {
			text := scope.get_own('text') or {
				panic('musi: print: no text provided')
			}
			print(scope.invoke('tostring', {'thing': text}) as string)
			return interpreter.empty
		}
	})

	scope.new('println', interpreter.ValueNativeFunction{
		tracer: 'println',
		args: ['text']
		code: fn (mut scope Scope) Value {
			text := scope.get_own('text') or {
				panic('musi: print: no text provided')
			}
			println(scope.invoke('tostring', {'thing': text}) as string)
			return interpreter.empty
		}
	})

	scope.new('each', interpreter.ValueNativeFunction{
		tracer: 'each',
		args: ['list', 'action']
		code: fn (mut scope Scope) Value {
			list := scope.get_own('list') or {
				panic('musi: each: no list provided')
			}
			action := scope.get_own('action') or {
				panic('musi: each: no action provided')
			}
			func := if action is interpreter.ValueFunction {
				interpreter.IFunctionValue(action)
			} else if action is interpreter.ValueNativeFunction {
				interpreter.IFunctionValue(action)
			} else {
				panic('musi: each: action must be a function')
			}
			if list is []interpreter.Value {
				for value in list {
					func.run(mut scope, {func.args[0]: value})
				}
			} else {
				panic('musi: each: list must be... a list')
			}
			return interpreter.empty
		}
	})
}
