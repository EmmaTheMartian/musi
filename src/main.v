module main

import os
import cli
import v.vmod
import tokenizer
import parser
import interpreter
import stdlib

fn main() {
	mod := vmod.decode(@VMOD_FILE)!
	mut cmd := cli.Command{
		name: 'musi'
		description: 'musi'
		version: mod.version
	}
	mut run := cli.Command{
		name: 'run'
		usage: '<file>'
		required_args: 1
		execute: fn (c cli.Command) ! {
			if !os.exists(c.args[0]) {
				eprintln('error: file `${c.args[0]}` does not exist.')
				exit(1)
			}

			write_debug_output := c.flags.get_bool('syntax-debug')!

			if write_debug_output && (!os.exists('debug') || !os.exists('debug/syntax')) {
				os.mkdir_all('debug/syntax/') or {
					eprintln('error: failed to create ./debug/syntax/ folders')
					exit(1)
				}
			}

			s := os.read_file(c.args[0])!

			mut t := tokenizer.Tokenizer{
				input: s
				ilen: s.len
			}

			t.tokenize()
			if write_debug_output {
				tokenizer.write_tokens_to_file(t.tokens, 'debug/syntax/tokens.txt')!
			}

			ast := parser.parse(t.tokens)
			if write_debug_output {
				os.write_file('debug/syntax/ast.txt', ast.str())!
			}

			mut i := interpreter.Interpreter.new()
			if !c.flags.get_bool('no-std')! {
				stdlib.apply_builtins(mut i.scope)
			}
			i.run(ast)
		}
	}
	run.add_flag(cli.Flag{
		flag:          .bool
		name:          'syntax-debug'
		description:   'Enables tokenizer and parser debug output'
	})
	run.add_flag(cli.Flag{
		flag:          .bool
		name:          'no-std'
		abbrev:        '-S'
		description:   'Disables the standard library'
	})
	cmd.add_command(run)
	cmd.setup()
	cmd.parse(os.args)
}
