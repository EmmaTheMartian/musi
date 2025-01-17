module ast

import musi { Value }
import musi.tokenizer

pub interface INode {
	visit(mut IVisitor)
}

pub interface IVisitor {
mut:
	walk(AST)
}

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

pub fn (node NodeInvoke) visit(mut visitor IVisitor) Value {}

pub struct NodeString implements INode {
pub:
	value string
}

pub fn (node NodeString) visit(mut visitor IVisitor) Value {}
