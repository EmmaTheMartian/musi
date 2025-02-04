module repl

import os
import term
import readline
import interpreter
import stdlib

@[heap; noinit]
pub struct REPL {
pub mut:
	rl readline.Readline
	vm interpreter.Interpreter
}

@[inline]
pub fn REPL.new() REPL {
	return REPL{
		vm: interpreter.Interpreter.new('.', interpreter.InterpreterOptions{}, fn (mut scope interpreter.Scope) {
			stdlib.apply_stdlib(mut scope)
		})
	}
}

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
	}
}
