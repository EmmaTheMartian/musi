module stdlib

import interpreter { Scope, Value, ValueNativeFunction }

@[inline]
fn eval_runfile(mut scope Scope) Value {
	path := scope.get_fn_arg[string]('path', 'runfile')
	scope.interpreter.push_trace(path, 'runfile', -1, -1)
	result := scope.interpreter.run_file_isolated(path)
	scope.interpreter.pop_trace()
	return result
}

@[inline]
fn eval_runstring(mut scope Scope) Value {
	scope.interpreter.push_trace('<string>', 'runstring', -1, -1)
	result := scope.interpreter.run_file_isolated(scope.get_fn_arg[string]('string', 'runstring'))
	scope.interpreter.pop_trace()
	return result
}

pub const eval_module = {
	'runfile':   Value(ValueNativeFunction{
		args: ['path']
		code: eval_runfile
	})
	'runstring': Value(ValueNativeFunction{
		args: ['string']
		code: eval_runstring
	})
}

// apply_eval applies the `eval` module to the given scope.
@[inline]
pub fn apply_eval(mut scope Scope) {
	scope.new('eval', eval_module)
}
