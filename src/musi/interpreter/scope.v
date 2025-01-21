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
			variable := s.get(node.func)
			if variable is ValueFunction {
				mut args := map[string]Value{}
				for index, arg in node.args {
					args[variable.args[index]] = s.eval(arg)
				}
				return variable.run(mut s, args)
			} else if variable is ValueNativeFunction {
				mut args := map[string]Value{}
				for index, arg in node.args {
					args[variable.args[index]] = s.eval(arg)
				}
				return variable.run(mut s, args)
			} else {
				eprintln('musi: attempted to invoke non-function: ${node.func}')
			}
		}
		ast.NodeString {
			return node.value
		}
		ast.NodeId {
			return s.get(node.value) or {
				eprintln('musi: unknown variable: ${node.value}')
				exit(1)
			}
		}
		ast.NodeBlock {
			return ValueFunction{
				tracer: 'anon'
				code: node
				args: []
			}
		}
		ast.NodeRoot {
			for child in node.children {
				s.eval(child)
			}
		}
		else {
			eprintln('musi: attempted to eval() node of invalid type: ${node}')
		}
	}
	return empty
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
		return s.scope_of(variable)
	} else {
		return none
	}
}

@[inline]
pub fn (s &Scope) get(variable string) ?Value {
	if variable in s.variables {
		return s.variables[variable] or {
			panic('uhh, i do not even know what this error would be caused by. just... report it please.')
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
	// we use has_own instead of has so that people can make variables with the same name in lower scopes
	if s.has_own(variable) {
		eprintln('musi: cannot create a new variable that already exists: ${variable}')
		exit(1)
	} else {
		s.variables[variable] = value
	}
}

@[inline]
pub fn (mut s Scope) set(variable string, value Value) {
	mut scope := s.scope_of(variable) or {
		eprintln('musi: cannot set a non-existent variable: ${variable}')
		exit(1)
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
