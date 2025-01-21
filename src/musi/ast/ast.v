module ast

pub interface INode { }

@[heap]
pub type AST = NodeRoot

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

pub struct NodeEOF implements INode { }
