module parser

import musi.ast
import musi.tokenizer { Token, TokenKind }

pub struct Parser {
pub mut:
	index  int
	tokens []Token
}

// eat gets the next token from the parser. nom
@[inline; direct_array_access]
pub fn (mut p Parser) eat() ?Token {
	if p.index >= p.tokens.len {
		return none
	}
	s := p.tokens[p.index]
	p.index++
	return s
}

@[inline]
pub fn (mut p Parser) skip() {
	p.index++
}

@[inline; direct_array_access]
pub fn (mut p Parser) peek() Token {
	return p.tokens[p.index]
}

@[inline; direct_array_access]
pub fn (mut p Parser) peek_n(n int) Token {
	return p.tokens[p.index + n]
}

@[inline]
pub fn (mut p Parser) expect_kind_n(kind TokenKind, n int) {
	t := p.peek_n(n)
	if t.kind != kind {
		panic('musi: unexpected token: ${t} (expected kind ${kind})')
	}
}

@[inline]
pub fn (mut p Parser) expect_kind(kind TokenKind) {
	p.expect_kind_n(kind, 0)
}

@[inline]
pub fn (mut p Parser) expect_n(kind TokenKind, value string, n int) {
	t := p.peek_n(n)
	if t.kind != kind {
		panic('musi: unexpected token: ${t} (expected `${kind}` with value `${value}`)')
	} else if t.value != value {
		panic('musi: expected `${t.value}` but got `${value}` (${t})')
	}
}

@[inline]
pub fn (mut p Parser) expect(kind TokenKind, value string) {
	p.expect_n(kind, value, 0)
}

@[inline]
pub fn (mut p Parser) check_n(kind TokenKind, value string, n int) bool {
	t := p.peek_n(n)
	// println('check_n ${t} == ${kind},${value}')
	return t.kind == kind && t.value == value
}

@[inline]
pub fn (mut p Parser) check(kind TokenKind, value string) bool {
	// print('peek: ')
	// println(p.peek_n(0))
	return p.check_n(kind, value, 0)
}

@[inline; direct_array_access]
fn (mut p Parser) tokens_until_closing(open_kind TokenKind, open_value string, close_kind TokenKind, close_value string, start_depth int) []Token {
	mut tokens := []Token{}
	mut depth := start_depth

	mut token := p.eat() or {
		panic('musi: reached eof before `${close_value}`')
	}

	println('tuc: ${token}')

	for depth != 0 {
		if p.check(open_kind, open_value) {
			// println('depth++ (${depth + 1})')
			depth++
		} else if p.check(close_kind, close_value) {
			// println('depth-- (${depth - 1})')
			depth--
		}

		tokens << token

		token = p.eat() or {
			panic('musi: reached eof before `${close_value}`')
		}
	}

	// tokens << token
	println('end of tuc: ${token}')

	return tokens
}

@[inline]
fn (mut p Parser) parse_invoke() ast.NodeInvoke {
	p.expect_kind_n(.id, -1)
	p.expect(.literal, '(')
	p.skip()
	return ast.NodeInvoke{
		p.tokens[p.index - 1].value,
		parse_list(p.tokens_until_closing(.literal, '(', .literal, ')', 1))
	}
}

@[inline]
fn (mut p Parser) parse_block() ast.NodeBlock {
	println('parse_block: ${p.peek_n(0)}')
	p.expect(.keyword, 'do')
	return ast.NodeBlock{
		parse_list(p.tokens_until_closing(.keyword, 'do', .keyword, 'end', 1))
	}
}

@[inline]
fn (mut p Parser) parse_fn() ast.NodeFn {
	p.expect_n(.keyword, 'fn', -1)
	args := p.tokens_until_closing(.literal, '(', .literal, ')', 1)
	// for arg in args {
	// 	if arg.kind != .id {
	// 		eprintln('musi: argument must be an identifier (got ${arg})')
	// 		exit(1)
	// 	}
	// }
	println('parsefn: ${p.peek()}')
	block := p.parse_block()
	return ast.NodeFn{
		args: args.map(|it| it.value),
		code: block
	}
}

@[inline]
fn (mut p Parser) parse_let() ast.NodeLet {
	p.expect_kind(.id)
	p.skip()
	p.expect(.literal, '=')
	p.skip()
	value := p.parse_single() or {
		panic('musi: unexpected eof before let value')
	}
	return ast.NodeLet{
		name: p.peek_n(-1).value
		value: value
	}
}

@[inline]
pub fn (mut p Parser) parse_single() ?ast.INode {
	token := p.eat() or {
		return none
	}
	println('poarse_singleZ: ${token}')
	match token.kind {
		.@none {
			panic('musi: parse_single given an empty token: ${token}')
		}
		.id {
			if p.check(.literal, '(') {
				return p.parse_invoke()
			} else {
				return ast.NodeId{token.value}
			}
		}
		.keyword {
			if token.value == 'let' {
				return p.parse_let()
			} else if token.value == 'fn' {
				return p.parse_fn()
			} else if token.value == 'do' {
				return p.parse_block()
			}
		}
		.operator { }
		.literal { }
		.str {
			return ast.NodeString{token.value}
		}
		.number { }
		.colon { }
		.semi { }
		.eof {
			return ast.NodeEOF{}
		}
	}
	panic('musi: parse_single given an invalid token: ${token}')
}

pub fn parse_list(tokens []Token) []ast.INode {
	mut p := Parser{ tokens: tokens }
	mut nodes := []ast.INode{}

	println('---\nparse_list: ${tokens}\n---')

	for {
		nodes << p.parse_single() or {
			return nodes
		}
	}

	return nodes
}

@[inline]
pub fn parse(tokens []Token) ast.AST {
	return ast.AST{ children: parse_list(tokens) }
}
