module ast

pub interface INode { }

@[heap]
pub type AST = NodeRoot

pub struct IfChainElement {
pub:
	// set to `none` for an else statement
	cond ?INode
	code INode
}

// Nodes

pub struct NodeRoot implements INode {
pub mut:
	children []INode
}

pub struct NodeInvoke implements INode {
pub:
	func string
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

pub struct NodeAssign implements INode {
pub:
	name  string
	value INode
}

pub struct NodeList implements INode {
pub:
	values []INode
}

pub struct NodeReturn implements INode {
pub:
	node INode
}

pub struct NodeIf implements INode {
pub:
	chain []IfChainElement
}

pub struct NodeEOF implements INode { }
