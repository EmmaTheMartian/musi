module parser

import ast
import tokenizer { Token, TokenKind }

// operators where nested operators should be given to the leftmost operator instead of the rightmost.
// nodes excluded from this list resolve as: 1 + 2 + 3 resolves to add(1, add(2, 3))
// nodes in this list resolve as: 1 + 2 + 3 resolves to add(add(1, 2), 3)
// const operators_with_left_priority = [
// 	// ast.Operator.assign,
// 	// ast.Operator.dot,
// ]
const operators_with_left_priority = []ast.Operator{}

// same as
// https://en.cppreference.com/w/c/language/operator_precedence
const operator_precedence = {
	ast.Operator.dot: 0
	.pipe:            1
	.unary_not:       2
	.bit_not:         2
	.div:             3
	.mul:             3
	.mod:             3
	.add:             4
	.sub:             4
	.shift_right:     5
	.shift_left:      5
	.gteq:            6
	.lteq:            6
	.gt:              6
	.lt:              6
	.eq:              7
	.neq:             7
	.bit_and:         8
	.bit_xor:         9
	.bit_or:          10
	.and:             11
	.or:              12
	.assign:          14
}

pub struct Parser {
pub mut:
	index  int
pub:
	tokens []Token
}

// throw throws a tokenizer error and shows the line and column (or token index, if not possible) where the error occurred.
@[noreturn]
pub fn (p &Parser) throw(msg string) {
	if p.index >= p.tokens.len {
		$if debug {
			println(p.tokens)
		}
		panic('musi: parser @ token #${p.index}/${p.tokens.len}: ${msg} (last token: ${p.tokens.last()})')
	}
	panic('musi: parser @ ${p.peek().line}:${p.peek().column}: ${msg}')
}

// eat gets the next token from the parser and increments the parser's index. nom
@[direct_array_access; inline]
fn (mut p Parser) eat() ?Token {
	if p.index >= p.tokens.len {
		return none
	}
	s := p.tokens[p.index]
	p.index++
	return s
}

// skip increments the parser's index without returning anything.
@[inline]
fn (mut p Parser) skip() {
	p.index++
}

// peek returns the current token.
@[direct_array_access; inline]
fn (p &Parser) peek() Token {
	return p.tokens[p.index]
}

// peek_n returns the token offset by `n` from the current index.
@[direct_array_access; inline]
fn (p &Parser) peek_n(n int) Token {
	return p.tokens[p.index + n]
}

// expect_kind_n checks if the token at the parser's index offset by `n` is the provided kind, and if not throws an error.
@[inline]
fn (p &Parser) expect_kind_n(kind TokenKind, n int) {
	t := p.peek_n(n)
	if t.kind != kind {
		p.throw('unexpected token: ${t} (expected kind ${kind})')
	}
}

// expect_kind checks if the current token is the provided kind, and if not throws an error.
@[inline]
fn (p &Parser) expect_kind(kind TokenKind) {
	p.expect_kind_n(kind, 0)
}

// expect_n checks if the token at the parser's index offset by `n` matches the provided kind and value, and if not throws an error.
@[inline]
fn (p &Parser) expect_n(kind TokenKind, value string, n int) {
	t := p.peek_n(n)
	if t.kind != kind {
		p.throw('unexpected token: ${t} (expected `${kind}` with value `${value}`)')
	} else if t.value != value {
		p.throw('expected `${value}` but got `${t.value}` (${t})')
	}
}

// expect checks if the current token matches the provided kind and value, and if not throws an error.
@[inline]
fn (p &Parser) expect(kind TokenKind, value string) {
	p.expect_n(kind, value, 0)
}

// check_n returns true if the token at the parser's index offset by `n` matches the provided kind and value.
@[inline]
fn (p &Parser) check_n(kind TokenKind, value string, n int) bool {
	t := p.peek_n(n)
	return t.kind == kind && t.value == value
}

// check returns true if the current token matches the provided kind and value.
@[inline]
fn (p &Parser) check(kind TokenKind, value string) bool {
	return p.check_n(kind, value, 0)
}

// check_kind_n returns true if the token at the parser's index offset by `n` matches the provided kind.
@[inline]
fn (p &Parser) check_kind_n(kind TokenKind, n int) bool {
	return p.peek_n(n).kind == kind
}

// check_kind returns true if the current token matches the provided kind.
@[inline]
fn (p &Parser) check_kind(kind TokenKind) bool {
	return p.check_kind_n(kind, 0)
}

// check_value_n returns true if the token at the parser's index offset by `n` matches the provided value.
@[inline]
fn (p &Parser) check_value_n(value string, n int) bool {
	return p.peek_n(n).value == value
}

// check_value returns true if the current token matches the provided value.
@[inline]
fn (p &Parser) check_value(value string) bool {
	return p.check_value_n(value, 0)
}

// tokens_until_closing gets all tokens in between open_kind/open_value and close_kind/close_value.
// when `start_with_open_value` is true, the function will call `Parser.expect(open_kind, open_value)`
// also see: tokens_until
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

// tokens_until gets all tokens until the given kind.
// also see: tokens_until_closing
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

// parse_invoke parses tokens expecting to build an `ast.NodeInvoke`.
// the provided `node` is the function, this will often be an identifier or dot operator.
// the current node must be a `(` literal.
@[inline]
fn (mut p Parser) parse_invoke(node ast.INode) ast.NodeInvoke {
	args := p.tokens_until_closing(.literal, '(', .literal, ')', true)
	return ast.NodeInvoke{node, parse_comma_list(args, false)}
}

// parse_block parses tokens expecting to build an `ast.NodeBlock`.
// the current node must be a `do` keyword.
@[inline]
fn (mut p Parser) parse_block() ast.NodeBlock {
	p.expect(.keyword, 'do')
	tokens := p.tokens_until_closing(.keyword, 'do', .keyword, 'end', true)
	return ast.NodeBlock{parse_list(tokens)}
}

// parse_fn parses tokens expecting to build an `ast.NodeFn`.
// the current node must be the token *after* a `fn` keyword.
@[inline]
fn (mut p Parser) parse_fn() ast.NodeFn {
	p.expect_n(.keyword, 'fn', -1)
	args := p.tokens_until(.keyword, 'do')
	// check if the last element is not an identifier. this would be the case if a trailing comma exists
	if args.len > 0 && args[args.len - 1].kind != .id {
		p.throw('expected identifier but got `${args[args.len - 1].value}`')
	}
	mut parsed_args := []string{}
	for i := 0; i < args.len; i += 2 {
		if args[i].kind != .id {
			p.throw('expected identifier but got `${args[i].value}`')
		}

		parsed_args << args[i].value

		// expect a comma, unless this is the last argument
		if i != args.len - 1 {
			expected_comma := args[i + 1]
			if expected_comma.kind != .literal || expected_comma.value != ',' {
				p.throw('expected a comma (,) but got ${args[i].value}')
			}
		}
	}
	// skip commas in the arguments
	block := p.parse_block()
	return ast.NodeFn{
		args: parsed_args
		code: block
	}
}

// parse_let parses tokens expecting to build an `ast.NodeLet`.
// the current node must be the token *after* a `let` keyword.
@[inline]
fn (mut p Parser) parse_let() ast.NodeLet {
	p.expect_n(.keyword, 'let', -1)
	p.expect_kind(.id)
	name := p.peek().value
	p.skip()
	p.expect(.operator, '=')
	p.skip()
	value := p.parse_single() or { p.throw('unexpected eof before let value') }
	return ast.NodeLet{
		name:  name
		value: value
	}
}

// parse_return parses tokens expecting to build an `ast.NodeReturn`.
// the current node must be the token *after* a `return` keyword.
@[inline]
fn (mut p Parser) parse_return() ast.NodeReturn {
	p.expect_n(.keyword, 'return', -1)
	node := p.parse_single() or { p.throw('unexpected eof before return value') }
	return ast.NodeReturn{
		node: node
	}
}

// parse_list parses tokens expecting to build an `ast.NodeList`.
// the current node must be the token *after* a `[` literal.
@[inline]
fn (mut p Parser) parse_list() ast.NodeList {
	p.expect_n(.literal, '[', -1)
	tokens := p.tokens_until_closing(.literal, '[', .literal, ']', false)
	return ast.NodeList{
		values: parse_comma_list(tokens, true)
	}
}

// parse_table parses tokens expecting to build an `ast.NodeTable`.
// the current node must be the token *after* a `{` keyword.
@[inline]
fn (mut p Parser) parse_table() ast.NodeTable {
	p.expect_n(.literal, '{', -1)

	mut data := map[string]ast.INode{}

	for !p.check(.literal, '}') {
		if p.check_kind(.id) || p.check_kind(.str) {
			name := p.peek().value
			p.skip()
			p.expect(.operator, '=')
			p.skip()
			value := p.parse_single() or { p.throw('unexpected EOF') }
			// optional comma
			if p.check(.literal, ',') {
				p.skip()
			}

			data[name] = value
		} else {
			p.throw('expected identifier or string but got `${p.peek().value}')
		}
	}

	p.expect(.literal, '}')
	p.skip()

	return ast.NodeTable{
		values: data
	}
}

// parse_if parses tokens expecting to build an `ast.NodeIf`.
// this will also parse corresponding `elseif` and `else` statements.
// the current node must be the token *after* an `if` keyword.
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

// parse_while parses tokens expecting to build an `ast.NodeWhile`.
// the current node must be the token *after* an `while` keyword.
@[inline]
pub fn (mut p Parser) parse_while() ast.NodeWhile {
	p.expect_n(.keyword, 'while', -1)
	cond := p.parse_single() or {
		p.throw('expected expression after `while` keyword.')
	}
	code := p.parse_block()
	return ast.NodeWhile{cond, code}
}

@[params]
pub struct ParseSingleParams {
pub:
	is_nested_operator bool
}

// parse_single parses the next AST node and returns it, it will return `none` when no more tokens remain (i.e, an EOF).
@[inline]
pub fn (mut p Parser) parse_single(params ParseSingleParams) ?ast.INode {
	token := p.eat() or { return none }
	mut node := ?ast.INode(none)
	match token.kind {
		.@none {
			p.throw('parse_single given an empty token: ${token}')
		}
		.id {
			node = ast.NodeId{token.value}
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
			} else if token.value == 'while' {
				node = p.parse_while()
			}
		}
		.literal {
			if token.value == '[' {
				node = p.parse_list()
			} else if token.value == '{' {
				node = p.parse_table()
			}
		}
		.str {
			node = ast.NodeString{token.value}
		}
		.number {
			node = ast.NodeNumber{token.value.f64()}
		}
		.boolean {
			node = ast.NodeBool{token.value == 'true'}
		}
		.null {
			node = ast.NodeNull{}
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
			} else {
				p.throw('attempted to parse non-unary operator. this error should never happen, please report it.')
			}
			// all other operators are handled below
		}
		.eof {
			node = ast.NodeEOF{}
		}
	}

	if node == none {
		p.throw('parse_single produced a `none` node. token: ${token}')
	}

	// if the next token is an operator, instead of returning this token, we
	// will return the operator with this as the `left` value.
	p.check_for_operator(params, mut node or {
		p.throw('parse_single node was none but we previously checked it was not. If this error occurs then your computer was probably hit with solar rays.')
	})

	// if the next token is an open parenthesis, we are invoking something
	if p.check(.literal, '(') {
		node = p.parse_invoke(node or {
			p.throw('`node` was assigned previously but is now none. If this error occurs then your computer was likely hit with solar rays.')
		})
		p.check_for_operator(params, mut node)
	}

	return node
}

// check_for_operator checks if the current node being parsed is an operator, and if so, parses it, **mutating the provided `node` value.**
// requires context of the current node being parsed (`node`) and the parameters passed into `parse_single` (`params`).
// **the `node` value is mutated into an operator, not returned.**
@[inline]
fn (mut p Parser) check_for_operator(params ParseSingleParams, mut node ast.INode) {
	if p.check_kind(.operator) && !p.check_value('!') && !p.check_value('~') {
		operator := p.eat() or {
			p.throw('parse_single failed to get an operator that we KNOW exists. If this error occurs then your computer was probably hit with solar rays.')
		}

		node_not_none := node

		mut next_node := p.parse_single(is_nested_operator: true) or {
			p.throw('right side of operator was none. error: ${err}')
		}

		next_node_has_priority := if mut next_node is ast.NodeOperator {
			if next_node.kind in operators_with_left_priority {
				true
			} else {
				precedence_of_node(next_node) > precedence_of_token(operator)
			}
		} else {
			false
		}

		if next_node_has_priority && mut next_node is ast.NodeOperator {
			next_node.left = ast.NodeOperator{
				kind:  get_operator_kind_from_str(operator.value)
				left:  node_not_none
				right: next_node.left
			}
			node = *next_node
		} else {
			node = ast.NodeOperator{
				kind:  get_operator_kind_from_str(operator.value)
				left:  node_not_none
				right: next_node
			}
		}
	}
}

// parse_list parses a list of tokens, creating a parser in the process.
// returns the list of parsed nodes.
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

// parse_comma_list parses a list of tokens, expecting a comma in between each statement.
// returns the list of parsed nodes.
@[inline]
pub fn parse_comma_list(tokens []Token, allow_trailing_comma bool) []ast.INode {
	mut p := Parser{
		tokens: tokens
	}
	mut nodes := []ast.INode{}

	for {
		nodes << p.parse_single() or { break }
		// if this is the last node, we do not need a comma
		if p.index < p.tokens.len {
			p.expect(.literal, ',')
			p.skip()
		}
	}

	if !allow_trailing_comma && p.index < p.tokens.len && p.check(.literal, ',') {
		p.throw('unexpected comma (,)')
	}

	return nodes
}

// parse parses the provided list of tokens and returns them as an `ast.AST` to be interpreted.
@[inline]
pub fn parse(tokens []Token) ast.AST {
	return ast.AST{
		children: parse_list(tokens)
	}
}

// get_operator_kind_from_str gets the `ast.Operator` for the provided `value`.
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
	else if value == '=' { .assign }
	else {
		panic('musi: get_operator_kind_from_str: given invalid value: ${value}')
	}
	// vfmt on
}

// precedence_of_node gets operator precedence based on the provided AST node.
// also see precedence_of_token.
@[inline]
pub fn precedence_of_node(node &ast.NodeOperator) int {
	return operator_precedence[node.kind]
}

// precedence_of_token gets operator precedence based on the provided token.
// also see precedence_of_node.
@[inline]
pub fn precedence_of_token(token &Token) int {
	return operator_precedence[get_operator_kind_from_str(token.value)]
}
