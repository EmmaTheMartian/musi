module stdlib

import interpreter { Scope, Value, ValueFunction, ValueNativeFunction }

pub struct TestingContext {
pub mut:
	passed int
	failed int
}

pub const testing_module = [
	ValueNativeFunction.new('test', ['name', 'actual', 'expected'], fn (mut scope Scope) Value {
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
	}),
	ValueNativeFunction.new('context', ['name', 'tests'], fn (mut scope Scope) Value {
		name := scope.get_fn_arg[string]('name', 'context')
		tests := scope.get_fn_arg[[]Value]('tests', 'context')
		mut passed := 0
		mut failed := 0
		for test in tests {
			if test is bool {
				if test { passed++ } else { failed++ }
			} else if test is ValueFunction {
				result := test.run(mut scope, {})
				if result is bool {
					if result { passed++ } else { failed++ }
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
	}),
	ValueNativeFunction.new('fncontext', ['name', 'test_fn'], fn (mut scope Scope) Value {
		name := scope.get_fn_arg[string]('name', 'fncontext')
		test_fn := scope.get_fn_arg[ValueFunction]('test_fn', 'fncontext')
		mut passed := 0
		mut failed := 0
		test_fn.run(mut scope, {})
		total := passed + failed
		if passed == total {
			println('${name}: \033[32mall ${passed} tests passed\033[0m')
		} else {
			println('${name}: \033[31m${failed} out of ${total} tests passed\033[0m')
		}
		return passed == total
	}),
]

// apply_testing applies the `testing` module to the given scope.
@[inline]
pub fn apply_testing(mut scope Scope) {
	mut mod := map[string]Value{}
	for func in testing_module {
		mod[func.tracer.source] = func
	}
	scope.new('testing', mod)
}
