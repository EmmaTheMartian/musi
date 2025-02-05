module stdlib

import interpreter { Scope, Value, ValueFunction, ValueNativeFunction }

pub struct TestingContext {
pub mut:
	passed int
	failed int
}

pub const testing_module = {
	'test': Value(ValueNativeFunction{
		args: ['name', 'actual', 'expected']
		code: fn (mut scope Scope) Value {
			name := scope.get_fn_arg[string]('name', '<test>')
			actual := scope.get_fn_arg_raw('actual', '<test>')
			expected := scope.get_fn_arg_raw('expected', '<test>')

			if actual == expected {
				println('${name}: \033[32mpass\033[0m')
				return true
			} else {
				println('${name}: \033[31mfail\033[0m (expected `\033[34m${expected}\033[0m` but got `\033[32m${actual}\033[0m`)')
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
				if test is bool {
					if test { passed++ }
					else { failed++ }
				} else if test is ValueFunction {
					result := test.run(mut scope, {}, '<test:lambda>')
					if result is bool {
						if result { passed++ }
						else { failed++ }
					} else {
						scope.throw('testing.context requires lambdas to return a boolean')
					}
				} else {
					scope.throw('testing.context requires all items in the list be a boolean or a lambda')
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
	'fncontext': ValueNativeFunction{
		args: ['name', 'test_fn']
		code: fn (mut scope Scope) Value {
			name := scope.get_fn_arg[string]('name', 'fncontext')
			test_fn := scope.get_fn_arg[ValueFunction]('test_fn', 'fncontext')
			mut passed := 0
			mut failed := 0
			test_fn.run(mut scope, {}, '<test_fn>')
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

// apply_testing applies the `testing` module to the given scope.
@[inline]
pub fn apply_testing(mut scope Scope) {
	scope.new('testing', testing_module)
}
