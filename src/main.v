module main

import os
import musi.tokenizer { Tokenizer }
import musi.parser { Parser }

fn main() {
	s := os.read_file('samples/html/html.musi')!
	mut t := Tokenizer{
		input: s
		ilen: s.len
	}
	println(t.input)

	t.tokenize()
	println(t.tokens)

	mut p := Parser{ tokens: t.tokens }
	p.parse()
}
