module tokenizer

import strings
import strings.textscanner { TextScanner }

pub const valid_id_start = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$'
pub const numbers = '1234567890'
pub const valid_id = valid_id_start + numbers
pub const literals = ';()[]{}\\'
pub const whitespace = ' \r\n\t\f'
pub const operators = [
	'==', '!=', '>', '>=', '<', '<=',
	'&&', '||',
	'++', '--',
	'<<', '>>',
]
pub const single_char_operators = '+-*/%^|&!:='
pub const keywords = []string{}

pub enum TokenKind {
	@none
	id
	keyword
	operator
	literal
	str
	number
	colon
	semi
}

pub struct Token {
pub:
	kind   TokenKind
	value  string
	line   int
	column int
}

pub struct Tokenizer {
	TextScanner
pub mut:
	line   int = 1
	column int
	tokens []Token
}

@[inline]
fn (mut t Tokenizer) next_str(quote_kind u8) Token {
	mut buffer := strings.new_builder(1)
	for {
		ch := t.next()
		t.column++

		if ch == -1 {
			eprintln('musi: reached EOL before string termination')
			exit(1)
		} else if ch == `\n` {
			t.line++
			t.column = 0
		} else if ch == quote_kind && t.peek_n(-1) != `\\` {
			return Token{.str, buffer.str(), t.line, t.column}
		}

		buffer << u8(ch)
	}
	panic('musi Tokenizer.next_str: escaped loop, this error should never happen.')
}

@[inline]
fn (mut t Tokenizer) next_id(start u8) Token {
	mut buffer := strings.new_builder(1)
	buffer << start
	for {
		ch := t.next()
		t.column++

		if !valid_id.contains_u8(u8(ch)) || ch == -1 {
			return Token{.id, buffer.str(), t.line, t.column}
		}

		buffer << u8(ch)
	}
	panic('musi Tokenizer.next_id: escaped loop, this error should never happen.')
}

@[inline]
fn (mut t Tokenizer) is_operator() bool {
	return single_char_operators.contains_u8(u8(t.current())) ||
		u8(t.current()).ascii_str() + u8(t.peek()).ascii_str() in operators
}

@[inline]
fn (mut t Tokenizer) next_operator() Token {
	if single_char_operators.contains_u8(u8(t.current())) {
		return Token{.operator, u8(t.current()).ascii_str(), t.line, t.column}
	} else {
		return Token{.operator, u8(t.current()).ascii_str() + u8(t.peek()).ascii_str(), t.line, t.column}
	}
}

pub fn (mut t Tokenizer) tokenize() {
	for {
		ch := t.next()
		t.column++

		if ch == -1 {
			break
		} else if whitespace.contains_u8(u8(ch)) {
			if ch == `\n` {
				t.line++
				t.column = 0
			}
		} else if ch == `'` {
			t.tokens << t.next_str(u8(ch))
		} else if ch == `"` {
			t.tokens << t.next_str(u8(ch))
		} else if t.is_operator() {
			t.tokens << t.next_operator()
		} else if literals.contains_u8(u8(ch)) {
			t.tokens << Token{.literal, u8(ch).ascii_str(), t.line, t.column}
		} else if valid_id_start.contains_u8(u8(ch)) {
			tok := t.next_id(u8(ch))
			if tok.value in keywords {
				t.tokens << Token{.keyword, tok.value, t.line, t.column}
			} else {
				t.tokens << tok
			}
		} else {
			eprintln('musi: unexpected character: ${u8(ch).ascii_str()} (${ch}) at ${t.line}:${t.column}')
		}
	}
}
