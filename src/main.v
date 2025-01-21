module main

import os
import musi.tokenizer
import musi.parser
import musi.interpreter
import musi.stdlib

fn main() {
	s := os.read_file('samples/hello.musi')!
	mut t := tokenizer.Tokenizer{
		input: s
		ilen: s.len
	}
	os.write_file('test/A_input.txt', t.input)!

	t.tokenize()
	tokenizer.write_tokens_to_file(t.tokens, 'test/B_tokens.txt')!

	ast := parser.parse(t.tokens)
	os.write_file('test/C_ast.txt', ast.str())!

	mut i := interpreter.Interpreter.new()
	stdlib.apply(mut i.scope)
	i.run(ast)
}
