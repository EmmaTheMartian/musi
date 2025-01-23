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
fn (mut p Parser) eat() ?Token {
	if p.index >= p.tokens.len {
		return none
	}
	s := p.tokens[p.index]
	p.index++
	return s
}

@[inline]
fn (mut p Parser) skip() {
	p.index++
}

@[inline; direct_array_access]
fn (mut p Parser) peek() Token {
	return p.tokens[p.index]
}

@[inline; direct_array_access]
fn (mut p Parser) peek_n(n int) Token {
	return p.tokens[p.index + n]
}

@[inline]
fn (mut p Parser) expect_kind_n(kind TokenKind, n int) {
	t := p.peek_n(n)
	if t.kind != kind {
		panic('musi: unexpected token: ${t} (expected kind ${kind})')
	}
}

@[inline]
fn (mut p Parser) expect_kind(kind TokenKind) {
	p.expect_kind_n(kind, 0)
}

@[inline]
fn (mut p Parser) expect_n(kind TokenKind, value string, n int) {
	t := p.peek_n(n)
	if t.kind != kind {
		panic('musi: unexpected token: ${t} (expected `${kind}` with value `${value}`)')
	} else if t.value != value {
		panic('musi: expected `${t.value}` but got `${value}` (${t})')
	}
}

@[inline]
fn (mut p Parser) expect(kind TokenKind, value string) {
	p.expect_n(kind, value, 0)
}

@[inline]
fn (mut p Parser) check_n(kind TokenKind, value string, n int) bool {
	t := p.peek_n(n)
	return t.kind == kind && t.value == value
}

@[inline]
fn (mut p Parser) check(kind TokenKind, value string) bool {
	return p.check_n(kind, value, 0)
}

@[inline; direct_array_access]
fn (mut p Parser) tokens_until_closing(open_kind TokenKind, open_value string, close_kind TokenKind, close_value string, start_with_open_value bool) []Token {
	mut tokens := []Token{}
	mut depth := 1

	if start_with_open_value {
		p.expect(open_kind, open_value)
		p.skip()
	}

	mut token := p.eat() or {
		panic('musi: reached eof before `${close_value}`')
	}

	for depth != 0 {
		if p.check(open_kind, open_value) {
			depth++
		} else if p.check(close_kind, close_value) {
			depth--
		}

		tokens << token

		token = p.eat() or {
			panic('musi: reached eof before `${close_value}`')
		}
	}

	return tokens
}

fn (mut p Parser) tokens_until(kind TokenKind, value string) []Token {
	mut tokens := []Token{}

	for {
		if p.check(kind, value) {
			break
		}
		tokens << p.eat() or {
			panic('musi: reached eof before `${value}`')
		}
	}

	return tokens
}

@[inline]
fn (mut p Parser) parse_invoke() ast.NodeInvoke {
	p.expect_kind_n(.id, -1)
	name := p.peek_n(-1).value
	args := p.tokens_until_closing(.literal, '(', .literal, ')', true)
	return ast.NodeInvoke{
		name,
		parse_list(args)
	}
}

@[inline]
fn (mut p Parser) parse_block() ast.NodeBlock {
	p.expect(.keyword, 'do')
	return ast.NodeBlock{
		parse_list(p.tokens_until_closing(.keyword, 'do', .keyword, 'end',true))
	}
}

@[inline]
fn (mut p Parser) parse_fn() ast.NodeFn {
	p.expect_n(.keyword, 'fn', -1)
	args := p.tokens_until(.keyword, 'do')
	block := p.parse_block()
	return ast.NodeFn{
		args: args.map(|it| it.value),
		code: block
	}
}

@[inline]
fn (mut p Parser) parse_let() ast.NodeLet {
	p.expect_kind(.id)
	name := p.peek().value
	p.skip()
	p.expect(.literal, '=')
	p.skip()
	value := p.parse_single() or {
		panic('musi: unexpected eof before let value')
	}
	return ast.NodeLet{
		name: name
		value: value
	}
}

@[inline]
fn (mut p Parser) parse_assign() ast.NodeAssign {
	p.expect_kind_n(.id, -1)
	name := p.peek_n(-1).value
	p.expect(.literal, '=')
	p.skip()
	value := p.parse_single() or {
		panic('musi: unexpected eof before assignment value')
	}
	return ast.NodeAssign{
		name: name
		value: value
	}
}

@[inline]
fn (mut p Parser) parse_list() ast.NodeList {
	p.expect_n(.literal, '[', -1)
	tokens := p.tokens_until_closing(.literal, '[', .literal, ']', false)
	return ast.NodeList{
		values: parse_list(tokens)
	}
}

@[inline]
pub fn (mut parser Parser) parse_single() ?ast.INode {
	token := parser.eat() or {
		return none
	}
	match token.kind {
		.@none {
			panic('musi: parse_single given an empty token: ${token}')
		}
		.id {
			// if the next token is an open parenthesis, we are invoking something
			if parser.check(.literal, '(') {
				return parser.parse_invoke()
			}
			// if the next token is an equals sign, we are assigning
			else if parser.check(.literal, '=') {
				return parser.parse_assign()
			} else {
				return ast.NodeId{token.value}
			}
		}
		.keyword {
			if token.value == 'let' {
				return parser.parse_let()
			} else if token.value == 'fn' {
				return parser.parse_fn()
			} else if token.value == 'do' {
				return parser.parse_block()
			}
		}
		.literal {
			if token.value == '[' {
				return parser.parse_list()
			}
		}
		.str {
			return ast.NodeString{token.value}
		}
		.number {
			return ast.NodeNumber{token.value.f64()}
		}
		.eof {
			return ast.NodeEOF{}
		}
	}
	panic('musi: parse_single given an invalid token: ${token}')
}

pub fn parse_list(tokens []Token) []ast.INode {
	mut parser := Parser{ tokens: tokens }
	mut nodes := []ast.INode{}

	for {
		nodes << parser.parse_single() or {
			break
		}
	}

	return nodes
}

@[inline]
pub fn parse(tokens []Token) ast.AST {
	return ast.AST{ children: parse_list(tokens) }
}
