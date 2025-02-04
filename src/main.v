module main

import os
import cli
import v.vmod
import tokenizer
import parser
import interpreter
import stdlib
import repl

fn main() {
	mod := vmod.decode(@VMOD_FILE)!

	mut cmd := cli.Command{
		name:        'musi'
		description: 'musi'
		version:     mod.version
	}

	// Subcommands
	mut run := cli.Command{
		name:          'run'
		usage:         '<file>'
		required_args: 1
		execute:       fn (c cli.Command) ! {
			input_file := c.args[0]

			if !os.exists(input_file) {
				eprintln('error: file `${input_file}` does not exist.')
				exit(1)
			}

			write_debug_output := c.flags.get_bool('syntax-debug')!

			if write_debug_output && (!os.exists('debug') || !os.exists('debug/syntax')) {
				os.mkdir_all('debug/syntax/') or {
					eprintln('error: failed to create ./debug/syntax/ folders')
					exit(1)
				}
			}

			s := os.read_file(input_file)!

			mut t := tokenizer.Tokenizer{
				input: s
				ilen:  s.len
			}

			t.tokenize()
			if write_debug_output {
				tokenizer.write_tokens_to_file(t.tokens, 'debug/syntax/tokens.txt')!
			}

			ast := parser.parse(t.tokens)
			if write_debug_output {
				os.write_file('debug/syntax/ast.txt', ast.str())!
			}

			root_import_dir := os.dir(input_file)
			opts := interpreter.InterpreterOptions{}
			use_stdlib := !c.flags.get_bool('no-std')!
			scope_init_fn := fn [use_stdlib] (mut scope interpreter.Scope) {
				if use_stdlib {
					stdlib.apply_stdlib(mut scope)
				}
			}

			mut i := interpreter.Interpreter.new(input_file, root_import_dir, opts, scope_init_fn)
			file_return_value := i.run(ast)

			if file_return_value != interpreter.null_value {
				println('returned: ${file_return_value}')
			}
		}
	}

	mut repl_cmd := cli.Command{
		name:    'repl'
		execute: fn (c cli.Command) ! {
			mut it := repl.REPL.new()
			it.run()
		}
	}

	// Flags
	run.add_flag(cli.Flag{
		flag:        .bool
		name:        'syntax-debug'
		description: 'Enables tokenizer and parser debug output'
	})

	run.add_flag(cli.Flag{
		flag:        .bool
		name:        'no-std'
		abbrev:      '-S'
		description: 'Disables the standard library'
	})

	// Run!
	cmd.add_command(run)
	cmd.add_command(repl_cmd)
	cmd.setup()
	cmd.parse(os.args)
}
