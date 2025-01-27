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
pub mut:
	left  INode
	right INode
pub:
	precedence int @[required]
}

// nodes

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

// operators

pub struct OperatorEquals {
	NodeOperator
pub:
	precedence int = 1
}

pub struct OperatorNotEquals {
	NodeOperator
pub:
	precedence int = 1
}

pub struct OperatorGtEq {
	NodeOperator
pub:
	precedence int = 1
}

pub struct OperatorLtEq {
	NodeOperator
pub:
	precedence int = 1
}

pub struct OperatorGt {
	NodeOperator
pub:
	precedence int = 1
}

pub struct OperatorLt {
	NodeOperator
pub:
	precedence int = 1
}

pub struct OperatorAnd {
	NodeOperator
pub:
	precedence int = 1
}

pub struct OperatorOr {
	NodeOperator
pub:
	precedence int = 1
}

pub struct OperatorRightShift {
	NodeOperator
pub:
	precedence int = 10
}

pub struct OperatorLeftShift {
	NodeOperator
pub:
	precedence int = 10
}

pub struct OperatorBitwiseAnd {
	NodeOperator
pub:
	precedence int = 10
}

pub struct OperatorBitwiseXor {
	NodeOperator
pub:
	precedence int = 10
}

pub struct OperatorBitwiseOr {
	NodeOperator
pub:
	precedence int = 10
}

pub struct OperatorAdd {
	NodeOperator
pub:
	precedence int = 100
}

pub struct OperatorSub {
	NodeOperator
pub:
	precedence int = 100
}

pub struct OperatorDiv {
	NodeOperator
pub:
	precedence int = 100
}

pub struct OperatorMul {
	NodeOperator
pub:
	precedence int = 100
}

pub struct OperatorMod {
	NodeOperator
pub:
	precedence int = 100
}

pub struct OperatorUnaryNot {
pub:
	value      INode
	precedence int = 1000
}

pub struct OperatorPipe {
	NodeOperator
pub:
	precedence int = 5
}

pub struct NodeEOF {}
