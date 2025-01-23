module interpreter

import musi.ast { INode, AST }

@[heap; noinit]
pub struct Scope {
pub mut:
	parent    &Scope @[required]
	tracer    string @[required] // used to help make tracebacks
	variables map[string]Value
}

pub fn (mut s Scope) eval(node &INode) Value {
	match node {
		ast.NodeInvoke {
			variable := s.get(node.func) or {
				panic('musi: no such function `${node.func}`')
			}

			mut args := map[string]Value{}
			if variable is ValueFunction {
				if node.args.len != variable.args.len {
					panic('musi: ${node.args.len} arguments provided but ${variable.args.len} are needed')
				}
				for index, arg in variable.args {
					args[arg] = s.eval(node.args[index])
				}
			} else if variable is ValueNativeFunction {
				if node.args.len != variable.args.len {
					panic('musi: ${node.args.len} arguments provided but ${variable.args.len} are needed. provided: ${node.args}')
				}
				for index, arg in variable.args {
					args[arg] = s.eval(node.args[index])
				}
			} else {
				panic('musi: attempted to invoke non-function: ${node.func}')
			}

			return s.invoke(node.func, args)
		}
		ast.NodeString {
			return node.value
		}
		ast.NodeNumber {
			return node.value
		}
		ast.NodeId {
			return s.get(node.value) or {
				panic('musi: unknown variable: ${node.value}')
			}
		}
		ast.NodeBlock {
			for child in node.nodes {
				s.eval(child)
			}
			return empty
		}
		ast.NodeFn {
			return ValueFunction{
				tracer: 'anonfn'
				code: node.code
				args: node.args
			}
		}
		ast.NodeLet {
			s.new(node.name, s.eval(node.value))
			return empty //todo: change this to return something useful
		}
		ast.NodeAssign {
			s.set(node.name, s.eval(node.value))
			return empty //todo: change this to return something useful
		}
		ast.NodeList {
			mut values := []Value{}
			for value in node.values {
				values << s.eval(value)
			}
			return values
		}
		ast.NodeRoot {
			for child in node.children {
				s.eval(child)
			}
			return empty
		}
		else {
			panic('musi: attempted to eval() node of invalid type: ${node}')
		}
	}
	panic('musi: eval() returned no value. this should never happen, please report it.')
}

pub fn (mut s Scope) invoke(func string, args map[string]Value) Value {
	variable := s.get(func)
	if variable is ValueFunction {
		return variable.run(mut s, args)
	} else if variable is ValueNativeFunction {
		return variable.run(mut s, args)
	} else {
		panic('musi: attempted to invoke non-function: ${func}')
	}
}

@[inline]
pub fn (s &Scope) has_own(variable string) bool {
	return variable in s.variables
}

@[inline]
pub fn (s &Scope) has(variable string) bool {
	return variable in s.variables ||
		(s.parent != unsafe { nil } && s.parent.has(variable))
}

@[inline]
pub fn (s &Scope) scope_of(variable string) ?&Scope {
	if s.has_own(variable) {
		return s
	} else if s.parent != unsafe { nil } {
		return s.parent.scope_of(variable)
	} else {
		return none
	}
}

@[inline]
pub fn (s &Scope) get(variable string) ?Value {
	if variable in s.variables {
		return s.variables[variable] or {
			panic('musi: failed to get a variable that... exists? this should never happen, please report this error')
		}
	} else if s.parent != unsafe { nil } {
		return s.parent.get(variable)
	} else {
		return none
	}
}

@[inline]
pub fn (s &Scope) get_own(variable string) ?Value {
	if variable in s.variables {
		return s.variables[variable] or {
			panic('uhh, i do not even know what this error would be caused by. just... report it please.')
		}
	} else {
		return none
	}
}

@[inline]
pub fn (mut s Scope) new(variable string, value Value) {
	// we use has_own instead of has so that people can make variables with the same name in child scopes
	if s.has_own(variable) {
		panic('musi: cannot create a new variable that already exists: ${variable}')
	} else {
		s.variables[variable] = value
	}
}

@[inline]
pub fn (mut s Scope) set(variable string, value Value) {
	mut scope := s.scope_of(variable) or {
		panic('musi: cannot set a non-existent variable: ${variable}')
	}
	scope.variables[variable] = value
}

@[inline]
pub fn (s &Scope) make_child(tracer string) Scope {
	child := Scope {
		parent: s
		tracer: tracer
	}
	return child
}

@[inline]
pub fn Scope.new() Scope {
	return Scope {
		parent: unsafe { nil }
		tracer: ''
	}
}
