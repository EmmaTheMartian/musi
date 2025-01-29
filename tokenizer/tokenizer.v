module tokenizer

import os
import strings
import strings.textscanner { TextScanner }

pub const valid_id_start = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$?'
pub const numbers = '1234567890'
pub const valid_number_runes = '.' + numbers // underscores are handled manually in parse_number
pub const valid_id = valid_id_start + numbers
pub const literals = ':;=()[]{},\\'
pub const whitespace = ' \r\n\t\f'
pub const keywords = [
	'fn',
	'do',
	'end',
	'if',
	'elseif',
	'else',
	'let',
	'return',
]
pub const operators = [
	// comparison
	'==',
	'!=',
	'>=',
	'<=',
	'>',
	'<',
	'&&',
	'||',
	// bitwise
	'>>',
	'<<',
	'&',
	'^',
	'|',
	'~',
	// math
	'+',
	'-',
	'/',
	'*',
	'%',
	// misc
	'!',
	'.',
	'->',
]

pub enum TokenKind {
	@none
	id
	keyword
	literal
	str
	number
	boolean
	operator
	eof
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

@[noreturn]
pub fn (t &Tokenizer) throw(msg string) {
	panic('musi: tokenizer @ ${t.line}:${t.column}: ${msg}')
}

@[inline]
fn (mut t Tokenizer) next_str(quote_kind u8) Token {
	mut buffer := strings.new_builder(0)
	mut ch := t.next()
	for {
		if ch == -1 {
			t.throw('reached EOF before string termination')
		} else if ch == `\n` {
			t.line++
			t.column = 0
		} else if ch == quote_kind && t.peek_n(-1) != `\\` {
			return Token{.str, buffer.str(), t.line, t.column}
		}

		buffer << u8(ch)
		ch = t.next()
		t.column++
	}
	t.throw('Tokenizer.next_str: escaped loop, this error should never happen.')
}

@[inline]
fn (mut t Tokenizer) next_id(start u8) Token {
	mut buffer := strings.new_builder(1)
	mut ch := int(start)
	for {
		if !valid_id.contains_u8(u8(t.peek())) || t.peek() == -1 {
			buffer << u8(ch)
			return Token{.id, buffer.str(), t.line, t.column}
		}

		buffer << u8(ch)
		ch = t.next()
		t.column++
	}
	t.throw('Tokenizer.next_id: escaped loop, this error should never happen.')
}

@[inline]
fn (mut t Tokenizer) next_number(start u8) Token {
	mut buffer := strings.new_builder(1)
	mut ch := int(start)
	for {
		if !valid_number_runes.contains_u8(u8(t.peek())) || t.peek() == -1 {
			buffer << u8(ch)
			s := buffer.str()
			if s.contains_u8(`.`) {
				if s[s.len - 1] == `.` {
					t.throw('number cannot end with a period')
				}
				if s.count('.') > 1 {
					t.throw('number cannot have more than one period (.) in it')
				}
			}
			return Token{.number, s, t.line, t.column}
		}

		buffer << u8(ch)
		ch = t.next()
		t.column++
	}
	t.throw('Tokenizer.next_number: escaped loop, this error should never happen.')
}

pub fn (mut t Tokenizer) tokenize() {
	mut ch := t.next()
	mut ch_with_next := '${u8(ch).ascii_str()}${u8(t.peek()).ascii_str()}'
	for {
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
		} else if ch_with_next in operators {
			t.skip()
			t.tokens << Token{.operator, ch_with_next, t.line, t.column}
		} else if u8(ch).ascii_str() in operators {
			t.tokens << Token{.operator, u8(ch).ascii_str(), t.line, t.column}
		} else if literals.contains_u8(u8(ch)) {
			t.tokens << Token{.literal, u8(ch).ascii_str(), t.line, t.column}
		} else if valid_number_runes.contains_u8(u8(ch)) {
			t.tokens << t.next_number(u8(ch))
		} else if valid_id_start.contains_u8(u8(ch)) {
			tok := t.next_id(u8(ch))
			if tok.value in keywords {
				t.tokens << Token{.keyword, tok.value, t.line, t.column}
			} else if tok.value == 'true' || tok.value == 'false' {
				t.tokens << Token{.boolean, tok.value, t.line, t.column}
			} else {
				t.tokens << tok
			}
		} else if ch == `#` {
			// continue until \n
			for ch != `\n` {
				ch = t.next()
			}
		} else {
			t.throw('unexpected character: ${u8(ch).ascii_str()} (${ch}) at ${t.line}:${t.column}')
		}

		ch = t.next()
		ch_with_next = '${u8(ch).ascii_str()}${u8(t.peek()).ascii_str()}'
		t.column++
	}
}

@[inline]
pub fn write_tokens_to_file(tokens []Token, path string) ! {
	os.write_file(path, tokens.map(|it| '<${it.kind}:${it.value}>').join('\n'))!
}
