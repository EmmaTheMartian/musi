module stdlib

import interpreter { Scope }

@[inline]
pub fn apply_stdlib(mut scope Scope) {
	apply_builtins(mut scope)
	apply_lists(mut scope)
	apply_strings(mut scope)
	apply_tables(mut scope)
}
