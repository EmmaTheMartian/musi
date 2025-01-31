module ast

pub interface INode {}

pub type AST = NodeRoot

pub struct IfChainElement {
pub:
	// set to `none` for an else statement
	cond ?INode
	code INode
}

pub struct NodeOperator implements INode {
pub:
	kind Operator
pub mut:
	// these are mutable so that we can modify existing nodes to account for precedence
	left  INode
	right INode
}

pub struct NodeUnaryOperator implements INode {
pub:
	kind  Operator
	value INode
}

pub enum Operator {
	// comparison
	eq
	neq
	gteq
	lteq
	gt
	lt
	and
	or
	// bitwise
	shift_right
	shift_left
	bit_and
	bit_xor
	bit_or
	bit_not
	// math
	add
	sub
	div
	mul
	mod
	// misc
	unary_not
	pipe
	dot
	assign
}

// nodes

pub struct NodeRoot implements INode {
pub mut:
	children []INode
}

pub struct NodeInvoke implements INode {
pub:
	func INode
	args []INode
}

pub struct NodeString implements INode {
pub:
	value string
}

pub struct NodeNumber implements INode {
pub:
	value f64
}

pub struct NodeBool implements INode {
pub:
	value bool
}

pub struct NodeNull {}

pub struct NodeId implements INode {
pub:
	value string
}

pub struct NodeBlock implements INode {
pub:
	nodes []INode
}

pub struct NodeFn implements INode {
pub:
	args []string
	code NodeBlock
}

pub struct NodeLet implements INode {
pub:
	name  string
	value INode
}

pub struct NodeList implements INode {
pub:
	values []INode
}

pub struct NodeTable implements INode {
pub:
	values map[string]INode
}

pub struct NodeReturn implements INode {
pub:
	node INode
}

pub struct NodeIf implements INode {
pub:
	chain []IfChainElement
}

pub struct NodeWhile implements INode {
pub:
	cond INode
	code NodeBlock
}

pub struct NodeEOF {}
