module ast

pub interface INode {
	line   int
	column int
}

pub struct BaseNode implements INode {
pub:
	line   int @[required]
	column int @[required]
}

pub type AST = NodeRoot

pub struct IfChainElement {
pub:
	line   int @[required]
	column int @[required]
	// set to `none` for an else statement
	cond INode
	code INode
}

pub struct NodeOperator implements INode {
	BaseNode
pub:
	kind Operator
pub mut:
	// these are mutable so that we can modify existing nodes to account for precedence
	left  INode
	right INode
}

pub struct NodeUnaryOperator implements INode {
	BaseNode
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
	BaseNode
pub:
	filepath string @[required]
pub mut:
	children []INode
}

pub struct NodeInvoke implements INode {
	BaseNode
pub:
	func INode
	args []INode
}

pub struct NodeString implements INode {
	BaseNode
pub:
	value string
}

pub struct NodeNumber implements INode {
	BaseNode
pub:
	value f64
}

pub struct NodeBool implements INode {
	BaseNode
pub:
	value bool
}

pub struct NodeNull {
	BaseNode
}

pub struct NodeId implements INode {
	BaseNode
pub:
	value string
}

pub struct NodeBlock implements INode {
	BaseNode
pub:
	nodes []INode
}

pub struct NodeFn implements INode {
	BaseNode
pub:
	args []string
	code NodeBlock
}

pub struct NodeLet implements INode {
	BaseNode
pub:
	name  string
	value INode
}

pub struct NodeList implements INode {
	BaseNode
pub:
	values []INode
}

pub struct NodeTable implements INode {
	BaseNode
pub:
	values map[string]INode
}

pub struct NodeReturn implements INode {
	BaseNode
pub:
	node INode
}

pub struct NodeIf implements INode {
	BaseNode
pub:
	chain []IfChainElement
}

pub struct NodeWhile implements INode {
	BaseNode
pub:
	cond INode
	code NodeBlock
}

pub struct NodeEOF {
	BaseNode
}

pub struct BlankNode implements INode {
pub:
	line   int = -1
	column int = -1
}

pub const blank_node := BlankNode{}
