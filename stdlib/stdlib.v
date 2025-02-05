module stdlib

import interpreter { Scope }

// apply_stdlib applies the entire standard library to the given scope.
@[inline]
pub fn apply_stdlib(mut scope Scope) {
	apply_builtins(mut scope)
	// apply_eval(mut scope)
	eval_module_.apply(mut scope)
	apply_files(mut scope)
	apply_lists(mut scope)
	apply_os(mut scope)
	apply_strings(mut scope)
	apply_tables(mut scope)
	apply_testing(mut scope)
}
