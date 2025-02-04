module stdlib

import interpreter { Scope, Value, ValueFunction, ValueNativeFunction }

pub const testing_module = {
	'test': Value(ValueNativeFunction{
		args: ['name', 'actual', 'expect']
		code: fn (mut scope Scope) Value {
			name := scope.get_fn_arg[string]('name', 'test')
			actual := scope.get_fn_arg_raw('actual', 'test')
			expect := scope.get_fn_arg_raw('expect', 'test')
			if actual == expect {
				println('${name}: pass')
				return true
			} else {
				println('${name}: fail (expected `\033[34m${expect}\033[0m` but got `\033[32m${actual}\033[0m`)')
				return false
			}
		}
	})
	'context': ValueNativeFunction{
		args: ['name', 'tests']
		code: fn (mut scope Scope) Value {
			name := scope.get_fn_arg[string]('name', 'context')
			tests := scope.get_fn_arg[[]Value]('tests', 'context')
			mut passed := 0
			mut failed := 0
			for test in tests {
				if test !is bool {
					scope.throw('testing.context requires all items in the list be a boolean')
				}
				if test as bool {
					passed++
				} else {
					failed++
				}
			}
			total := passed + failed
			if passed == total {
				println('${name}: \033[32mall ${passed} tests passed\033[0m')
			} else {
				println('${name}: \033[31m${failed} out of ${total} tests passed\033[0m')
			}
			return passed == total
		}
	}
}

@[inline]
pub fn apply_testing(mut scope Scope) {
	scope.new('testing', testing_module)
}
