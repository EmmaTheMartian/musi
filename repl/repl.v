module repl

import term
import readline
import interpreter
import stdlib

@[heap]
pub struct REPL {
pub mut:
	rl readline.Readline
	vm interpreter.Interpreter
}

// REPL.new creates a new REPL, it uses the default interpreter options and applies the stdlib.
@[inline]
pub fn REPL.new() REPL {
	return REPL{
		vm: interpreter.Interpreter.new('<repl>', '.', interpreter.InterpreterOptions{}, fn (mut scope interpreter.Scope) {
			stdlib.apply_stdlib(mut scope)
		})
	}
}

// run runs the given REPL.
pub fn (mut it REPL) run() {
	for {
		line := it.rl.read_line('> ') or {
			panic('failed to invoke read_line')
		}

		if line[0] == `\\` {
			if line == '\\q' {
				break
			} else if line == '\\clear' {
				term.clear()
			} else {
				println('no such repl command: ${line}')
			}
			continue
		}

		result := it.vm.run_string(line)

		if result != interpreter.null_value {
			println(result.to_string())
		}

		if it.vm.root_scope.returned != none {
			println(it.vm.root_scope.returned)
			break
		}
	}
}
