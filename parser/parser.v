module parser

import ast
import tokenizer { Token, TokenKind }

// tokens that we should check for operators after
const tokens_to_check_for_operators = [
	TokenKind.id,
	TokenKind.str,
	TokenKind.number,
]

pub struct Parser {
pub mut:
	index  int
	tokens []Token
}

@[noreturn]
pub fn (p &Parser) throw(msg string) {
	if p.index >= p.tokens.len {
		panic('musi: parser @ token #${p.index}/${p.tokens.len}: ${msg}')
	}
	panic('musi: parser @ ${p.peek().line}:${p.peek().column}: ${msg}')
}

// eat gets the next token from the parser. nom
@[direct_array_access; inline]
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

@[direct_array_access; inline]
fn (p &Parser) peek() Token {
	return p.tokens[p.index]
}

@[direct_array_access; inline]
fn (p &Parser) peek_n(n int) Token {
	return p.tokens[p.index + n]
}

@[inline]
fn (p &Parser) expect_kind_n(kind TokenKind, n int) {
	t := p.peek_n(n)
	if t.kind != kind {
		p.throw('unexpected token: ${t} (expected kind ${kind})')
	}
}

@[inline]
fn (p &Parser) expect_kind(kind TokenKind) {
	p.expect_kind_n(kind, 0)
}

@[inline]
fn (p &Parser) expect_n(kind TokenKind, value string, n int) {
	t := p.peek_n(n)
	if t.kind != kind {
		p.throw('unexpected token: ${t} (expected `${kind}` with value `${value}`)')
	} else if t.value != value {
		p.throw('expected `${value}` but got `${t.value}` (${t})')
	}
}

@[inline]
fn (p &Parser) expect(kind TokenKind, value string) {
	p.expect_n(kind, value, 0)
}

@[inline]
fn (p &Parser) check_n(kind TokenKind, value string, n int) bool {
	t := p.peek_n(n)
	return t.kind == kind && t.value == value
}

@[inline]
fn (p &Parser) check(kind TokenKind, value string) bool {
	return p.check_n(kind, value, 0)
}

@[inline]
fn (p &Parser) check_kind_n(kind TokenKind, n int) bool {
	return p.peek_n(n).kind == kind
}

@[inline]
fn (p &Parser) check_kind(kind TokenKind) bool {
	return p.check_kind_n(kind, 0)
}

@[inline]
fn (p &Parser) check_value_n(value string, n int) bool {
	return p.peek_n(n).value == value
}

@[inline]
fn (p &Parser) check_value(value string) bool {
	return p.check_value_n(value, 0)
}

@[direct_array_access; inline]
fn (mut p Parser) tokens_until_closing(open_kind TokenKind, open_value string, close_kind TokenKind, close_value string, start_with_open_value bool) []Token {
	mut tokens := []Token{}
	mut depth := 1

	start_token := p.peek()

	if start_with_open_value {
		p.expect(open_kind, open_value)
		p.skip()
	}

	mut token := p.eat() or {
		p.throw('reached eof before `${close_value}` (started at ${start_token.line}:${start_token.column})')
	}

	if token.kind == close_kind && token.value == close_value {
		return []
	}

	for depth != 0 {
		if p.check(open_kind, open_value) {
			depth++
		} else if p.check(close_kind, close_value) {
			depth--
		}

		tokens << token

		token = p.eat() or {
			p.throw('reached eof before `${close_value}` (started at ${start_token.line}:${start_token.column})')
		}
	}

	return tokens
}

fn (mut p Parser) tokens_until(kind TokenKind, value string) []Token {
	mut tokens := []Token{}

	start_token := p.peek()

	for {
		if p.check(kind, value) {
			break
		}
		tokens << p.eat() or {
			p.throw('reached eof before `${value}`  (started at ${start_token.line}:${start_token.column})')
		}
	}

	return tokens
}

@[inline]
fn (mut p Parser) parse_invoke() ast.NodeInvoke {
	p.expect_kind_n(.id, -1)
	name := p.peek_n(-1).value
	args := p.tokens_until_closing(.literal, '(', .literal, ')', true)
	return ast.NodeInvoke{name, parse_list(args)}
}

@[inline]
fn (mut p Parser) parse_block() ast.NodeBlock {
	p.expect(.keyword, 'do')
	tokens := p.tokens_until_closing(.keyword, 'do', .keyword, 'end', true)
	return ast.NodeBlock{parse_list(tokens)}
}

@[inline]
fn (mut p Parser) parse_fn() ast.NodeFn {
	p.expect_n(.keyword, 'fn', -1)
	args := p.tokens_until(.keyword, 'do')
	block := p.parse_block()
	return ast.NodeFn{
		args: args.map(|it| it.value)
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
	value := p.parse_single() or { p.throw('unexpected eof before let value') }
	return ast.NodeLet{
		name:  name
		value: value
	}
}

@[inline]
fn (mut p Parser) parse_return() ast.NodeReturn {
	p.expect_n(.keyword, 'return', -1)
	node := p.parse_single() or { p.throw('unexpected eof before return value') }
	return ast.NodeReturn{
		node: node
	}
}

@[inline]
fn (mut p Parser) parse_assign() ast.NodeAssign {
	p.expect_kind_n(.id, -1)
	name := p.peek_n(-1).value
	p.expect(.literal, '=')
	p.skip()
	value := p.parse_single() or { p.throw('unexpected eof before assignment value') }
	return ast.NodeAssign{
		name:  name
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
pub fn (mut p Parser) parse_if() ast.NodeIf {
	p.expect_n(.keyword, 'if', -1)

	mut chain := []ast.IfChainElement{}

	chain << ast.IfChainElement{
		cond: p.parse_single() or { p.throw('expected condition after `if` statement.') }
		code: p.parse_block()
	}

	// parse `elseif`s
	for {
		if p.check(.keyword, 'elseif') {
			p.skip()
			chain << ast.IfChainElement{
				cond: p.parse_single() or { p.throw('expected condition after `if` statement.') }
				code: p.parse_block()
			}
		} else if p.check(.keyword, 'else') {
			p.skip()
			chain << ast.IfChainElement{
				cond: none
				code: p.parse_block()
			}
			break
		} else {
			break
		}
	}

	return ast.NodeIf{chain}
}

@[inline]
pub fn (mut p Parser) parse_single() ?ast.INode {
	token := p.eat() or { return none }
	mut node := ?ast.INode(none)
	match token.kind {
		.@none {
			p.throw('parse_single given an empty token: ${token}')
		}
		.id {
			// if the next token is an open parenthesis, we are invoking something
			if p.check(.literal, '(') {
				node = p.parse_invoke()
			}
			// if the next token is an equals sign, we are assigning
			else if p.check(.literal, '=') {
				node = p.parse_assign()
			} else {
				node = ast.NodeId{token.value}
			}
		}
		.keyword {
			if token.value == 'let' {
				node = p.parse_let()
			} else if token.value == 'fn' {
				node = p.parse_fn()
			} else if token.value == 'do' {
				node = p.parse_block()
			} else if token.value == 'return' {
				node = p.parse_return()
			} else if token.value == 'if' {
				node = p.parse_if()
			} else if token.value == 'true' {
				node = ast.NodeBool{true}
			} else if token.value == 'false' {
				node = ast.NodeBool{false}
			}
		}
		.literal {
			if token.value == '[' {
				node = p.parse_list()
			}
		}
		.str {
			node = ast.NodeString{token.value}
		}
		.number {
			node = ast.NodeNumber{token.value.f64()}
		}
		.operator {
			if token.value == '!' {
				node = ast.NodeUnaryOperator{.unary_not, p.parse_single() or {
					p.throw('expected expression after unary not operator')
				}}
			} else if token.value == '~' {
				node = ast.NodeUnaryOperator{.bit_not, p.parse_single() or {
					p.throw('expected expression after bitwise not operator')
				}}
			}
			// all other operators are handled below
		}
		.eof {
			node = ast.NodeEOF{}
		}
	}

	if node == none {
		p.throw('parse_single returned a `none` node. token: ${token}')
	}

	// if the next token is an operator, instead of returning this token, we
	// will return the operator with this as the `left` value.
	if token.kind in tokens_to_check_for_operators && p.check_kind(.operator) && !p.check_value('!') {
		operator := p.eat() or {
			p.throw('parse_single failed to get an operator that we KNOW exists. If this error occurs then your computer was probably hit with solar rays.')
		}

		node_not_none := node or {
			p.throw('parse_single node was none but we previously checked it was not. If this error occurs then your computer was probably hit with solar rays.')
		}

		mut next_node := p.parse_single() or {
			p.throw('right side of operator was none. error: ${err}')
		}

		next_node_has_priority := if mut next_node is ast.NodeOperator {
			precedence_of_node(next_node) > precedence_of_token(operator)
		} else { false }

		next := if next_node_has_priority && mut next_node is ast.NodeOperator {
			next_node.left
		} else {
			ast.INode(next_node)
		}

		op_node := ast.NodeOperator{
			kind: get_operator_kind_from_str(operator.value),
			left: node_not_none,
			right: next
		}

		if next_node_has_priority && mut next_node is ast.NodeOperator {
			next_node.left = op_node
			return next_node
		}

		return op_node
	}

	return node
}

@[inline]
pub fn parse_list(tokens []Token) []ast.INode {
	mut p := Parser{
		tokens: tokens
	}
	mut nodes := []ast.INode{}

	for {
		nodes << p.parse_single() or { break }
	}

	return nodes
}

@[inline]
pub fn parse(tokens []Token) ast.AST {
	return ast.AST{
		children: parse_list(tokens)
	}
}

@[inline]
pub fn get_operator_kind_from_str(value string) ast.Operator {
	// vfmt off
	return if value == '==' { ast.Operator.eq }
	else if value == '!=' { .neq }
	else if value == '>=' { .gteq }
	else if value == '<=' { .lteq }
	else if value == '>' { .gt }
	else if value == '<' { .lt }
	else if value == '&&' { .and }
	else if value == '||' { .or }
	else if value == '>>' { .shift_right }
	else if value == '<<' { .shift_left }
	else if value == '&' { .bit_and }
	else if value == '^' { .bit_xor }
	else if value == '|' { .bit_or }
	else if value == '~' { .bit_not }
	else if value == '+' { .add }
	else if value == '-' { .sub }
	else if value == '/' { .div }
	else if value == '*' { .mul }
	else if value == '%' { .mod }
	else if value == '!' { .unary_not }
	else if value == '.' { .dot }
	else if value == '->' { .pipe }
	else {
		panic('musi: get_operator_kind_from_str: given invalid value: ${value}')
	}
	// vfmt on
}

// same as
// https://en.cppreference.com/w/c/language/operator_precedence
const operator_precedence = {
	ast.Operator.dot: 0,
	.pipe: 1,
	.unary_not: 2,
	.bit_not: 2,
	.div: 3,
	.mul: 3,
	.mod: 3,
	.add: 4,
	.sub: 4,
	.shift_right: 5,
	.shift_left: 5,
	.gteq: 6,
	.lteq: 6,
	.gt: 6,
	.lt: 6,
	.eq: 7,
	.neq: 7,
	.bit_and: 8,
	.bit_xor: 9,
	.bit_or: 10,
	.and: 11,
	.or: 12,
}

@[inline]
pub fn precedence_of_node(node &ast.NodeOperator) int {
	return operator_precedence[node.kind]
}

@[inline]
pub fn precedence_of_token(token &tokenizer.Token) int {
	return operator_precedence[get_operator_kind_from_str(token.value)]
}
