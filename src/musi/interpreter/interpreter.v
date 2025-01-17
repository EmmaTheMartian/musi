module interpreter

import datatypes { Stack }
import musi.parser.ast { IVisitor }
import musi { Value }

pub struct Interpreter implements IVisitor {
pub mut:
	stack Stack[Value]
	
}
