module main

import os
import musi.tokenizer
import musi.parser
import musi.interpreter
import musi.stdlib

fn main() {
	write_debug_output := '--debug' in os.args || '-d' in os.args

	if write_debug_output {
		os.mkdir('debug') or { }
	}

	if os.args.len < 2 {
		panic('error: no input file specified')
	}

	if !os.exists(os.args[1]) {
		panic('error: file ${os.args[1]} does not exist. usage: musi FILE [options]')
	}

	s := os.read_file(os.args[1])!
	mut t := tokenizer.Tokenizer{
		input: s
		ilen: s.len
	}
	if write_debug_output {
		os.write_file('debug/A_input.txt', t.input)!
	}

	t.tokenize()
	if write_debug_output {
		tokenizer.write_tokens_to_file(t.tokens, 'debug/B_tokens.txt')!
	}

	ast := parser.parse(t.tokens)
	if write_debug_output {
		os.write_file('debug/C_ast.txt', ast.str())!
	}

	mut i := interpreter.Interpreter.new()
	stdlib.apply_builtins(mut i.scope)
	i.run(ast)
}
