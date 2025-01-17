module parser

import musi.ast
import musi.tokenizer { Token, TokenKind }

pub struct Parser {
pub mut:
	index  int
	tokens []Token
}

// eat gets the next token from the parser
@[inline; direct_array_access]
pub fn (mut p Parser) eat() ?Token {
	if p.index >= p.tokens.len {
		return none
	}
	return p.tokens[p.index++]
}

@[inline]
pub fn (mut p Parser) skip() bool {
	if p.index >= p.tokens.len {
		return false
	}
	p.index++
	return true
}

@[inline; direct_array_access]
pub fn (mut p Parser) peek() Token {
	return p.tokens[p.index]
}

@[inline]
pub fn (mut p Parser) expect(kind TokenKind, value string) {
	t := p.peek()
	if (t.kind != kind) {
		eprintln('musi: unexpected token: ${t} (expected kind ${kind})')
		exit(1)
	} else if (t.value != value) {
		eprintln('musi: expected ${t.value} but got ${value} (${t})')
		exit(1)
	}
}

@[inline]
pub fn (mut p Parser) check(kind TokenKind, value string) bool {
	t := p.peek()
	return t.kind == kind && t.value == value
}

@[inline; direct_array_access]
fn (mut p Parser) tokens_until_closing(open_kind TokenKind, open_value string, close_kind TokenKind, close_value string, start_depth int) []Token {
	if start_depth <= 0 {
		panic('tokens_until_closing: start_depth must be >= 1')
	}

	mut tokens := []Token{}
	mut depth := start_depth

	mut token := Token{}
	for depth > 0 {
		token = p.next() or {
			eprintln('musi: reached eof before `${open_value}`')
			exit(1)
		}

		if p.check(open_kind, open_value) {
			depth++
			tokens << token
		} else if p.check(close_kind, close_value) {
			depth--
			// exclude the last closing brace
			if depth != 0 {
				tokens << token
			}
		} else {
			tokens << token
		}
	}
}

@[inline]
fn (mut p Parser) parse_invoke() ast.NodeInvoke {
	p.expect_value(.operator, ':')
	return ast.NodeInvoke{
		p.tokens[p.index - 1],
		p.parse_list(p.tokens_until_closing(.literal, ':', .literal, ';', 1))
	}
}

@[inline]
fn (mut p Parser) parse_operator() ast.INode {
	if p.check(.operator, ':') {
		return parse_invoke()
	} else {
		eprintln('musi: unknown operator: ${p.peek()}')
	}
}

pub fn (mut p Parser) parse_list(tokens []Token) []ast.INode {
	mut nodes := []ast.INode{}

	for token in tokens {
		match token.kind {
			.operator {
				nodes << p.parse_operator()
			}
			else {
				eprintln('parse_list: todo')
				exit(1)
			}
		}
	}

	return nodes
}

@[inline]
pub fn (mut p Parser) parse() ast.AST {
	return ast.AST{ children: p.parse_list(p.tokens) }
}
