module stdlib

import musi.interpreter { Scope, Value }

pub fn apply(mut scope Scope) {
	scope.new('print', interpreter.ValueNativeFunction{
		tracer: 'print',
		args: ['text']
		code: fn (mut scope Scope) Value {
			text := scope.get_own('text') or {
				eprintln('musi: print: no text provided')
				exit(1)
			}
			if text is string {
				println(text)
			} else {
				println(text.str())
			}
			return interpreter.empty
		}
	})
}
