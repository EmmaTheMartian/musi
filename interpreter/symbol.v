module interpreter

@[heap]
pub struct SymbolTable {
mut:
	symbols map[int]string
}

@[inline]
pub fn (mut table SymbolTable) put(symbol string) {
	table.symbols[symbol.hash()] = symbol
}

@[inline]
pub fn (mut table SymbolTable) pop(symbol string) {
	table.symbols.delete(symbol.hash())
}
