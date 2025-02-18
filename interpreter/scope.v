module interpreter

import ast { INode }
import tokenizer
import parser

// Scope represents a scope, containing information needed for executing code under an Interpreter.
@[heap; noinit]
pub struct Scope {
pub mut:
	interpreter &Interpreter @[required]
	parent      &Scope       @[required]
	file        string       @[required]
	line        int
	column      int
	variables   map[string]Value
	returned    ?Value
}

// throw throws an error with the given message.
// when not in production environments, a V `panic` is also invoked to give a V stacktrace.
@[noreturn]
pub fn (s &Scope) throw(message string) {
	eprintln('---')
	if s.interpreter.options.coloured_errors {
		eprintln('\033[31mmusi error\033[0m: ${message} (at \033[32m${s.file}\033[0m:\033[34m${s.line}\033[0m:\033[34m${s.column}\033[0m)')
		eprintln('\033[31mstacktrace\033[0m:')
		for trace in s.interpreter.stacktrace.array().reverse() {
			eprintln('  \033[32m${trace.file}\033[0m:\033[34m${trace.line}\033[0m:\033[34m${trace.column}\033[0m at \033[35m${trace.source}\033[0m')
		}
	} else {
		eprintln('musi error: ${message} (at ${s.file}:${s.line}:${s.column})')
		eprintln('stacktrace:')
		for trace in s.interpreter.stacktrace.array().reverse() {
			eprintln('  ${trace.file}:${trace.source}:${trace.line}:${trace.column}')
		}
	}
	eprintln('---')
	$if debug {
		panic(message)
	}
	exit(1)
}

// eval evaluates the given node under the scope and returns the evaluated value.
pub fn (mut s Scope) eval(node &INode) Value {
	s.line = node.line
	s.column = node.column
	match node {
		ast.NodeGroup {
			return s.eval(node.node)
		}
		ast.NodeInvoke {
			return s.invoke_node(node)
		}
		ast.NodeString {
			return node.value
		}
		ast.NodeNumber {
			return node.value
		}
		ast.NodeBool {
			return node.value
		}
		ast.NodeNull {
			return null_value
		}
		ast.NodeId {
			it := if node.value[0] == `@` {
				node.value[1..]
			} else {
				node.value
			}
			return s.get(it) or { s.throw('unknown variable identifier: ${it}') }
		}
		ast.NodeBlock {
			for child in node.nodes {
				s.eval(child)
				if s.returned != none {
					return s.returned
				}
			}
			return s.returned or { null_value }
		}
		ast.NodeFn {
			return ValueFunction{
				code:   node.code
				args:   node.args
				tracer: Trace{s.file, 'fn', s.line, s.column}
			}
		}
		ast.NodeMacro {
			return ValueFunction{
				code:   node.code
				args:   ['tokens']
				tracer: Trace{s.file, 'macro', s.line, s.column}
				macro:  true
			}
		}
		ast.NodeLet {
			value := s.eval(node.value)
			s.new(node.name, value)
			return value
		}
		ast.NodeList {
			mut values := []Value{}
			for value in node.values {
				values << s.eval(value)
			}
			return values
		}
		ast.NodeTable {
			mut values := map[string]Value{}
			for name, value in node.values {
				values[name] = s.eval(value)
			}
			return values
		}
		ast.NodeReturn {
			s.returned = s.eval(node.node)
			return s.returned or { null_value }
		}
		ast.NodeIf {
			for chain_link in node.chain {
				if chain_link.cond != INode(ast.blank_node) {
					if s.eval(chain_link.cond) == Value(true) {
						return s.eval(chain_link.code)
					}
				} else {
					return s.eval(chain_link.code)
				}
			}
			return null_value
		}
		ast.NodeWhile {
			for s.eval(node.cond) == true_value {
				mut c := s.make_child()
				c.eval(node.code)
			}
			return null_value
		}
		ast.NodeUnaryOperator {
			match node.kind {
				// .bitwise_not { return Value(f64(int(s.eval(node.left) as f64) ~ int(s.eval(node.right) as f64))) }
				.unary_not {
					result := s.eval(node.value)
					if result is bool {
						return Value(!(result as bool))
					} else {
						s.throw('cannot use unary not operator (!) on non-bool value (${result})')
					}
				}
				else {
					s.throw('eval() given a NodeUnaryOperator with an invalid kind (${node.kind}). This error should never happen, please report it.')
				}
			}
		}
		ast.NodeOperator {
			return s.eval_operator(node)
		}
		ast.NodeRoot {
			for child in node.children {
				s.eval(child)
				if s.returned != none {
					return s.returned
				}
			}
			return s.returned or { null_value }
		}
		else {
			s.throw('attempted to eval() node of invalid type: ${node}')
		}
	}
	s.throw('eval() returned no value. this should never happen, please report it.')
}

// process_tokens tokenizes, processes, and evaluates the given tokens in the current scope.
// this is used primarily for macros.
// the returned value is the evaluated value of the last node provided.
@[inline]
pub fn (mut s Scope) process_tokens(tokens []tokenizer.Token) Value {
	parsed := parser.parse_list(tokens)
	mut values := []Value{}
	for node in parsed {
		values << s.eval(node)
	}
	return values.last()
}

// eval_function evaluates the provided function value with the provided args, then returns the function's returned value.
// see also: invoke
pub fn (mut s Scope) eval_function(function Value, args map[string]Value) Value {
	if function is ValueFunction {
		return function.run(mut s, args)
	} else if function is ValueNativeFunction {
		return function.run(mut s, args)
	} else {
		s.throw('attempted to invoke non-function: ${function}')
	}
}

// eval_function_list_args evaluates the provided function value with the provided args, then returns the function's returned value.
// see also: invoke
pub fn (mut s Scope) eval_function_list_args(function Value, args []Value) Value {
	if function is ValueFunction {
		mut func_args := map[string]Value{}
		for i, value in args {
			func_args[function.args[i]] = value
		}
		return function.run(mut s, func_args)
	} else if function is ValueNativeFunction {
		mut func_args := map[string]Value{}
		for i, value in args {
			func_args[function.args[i]] = value
		}
		return function.run(mut s, func_args)
	} else {
		s.throw('attempted to invoke non-function: ${function}')
	}
}

// invoke invokes the function with the provided name using the provided args, then returns the function's returned value.
// see also: eval_function
@[inline]
pub fn (mut s Scope) invoke(func string, args map[string]Value) Value {
	variable := s.get(func) or { s.throw('cannot invoke non-existent function `${func}`') }
	if variable is ValueFunction {
		return variable.run(mut s, args)
	} else if variable is ValueNativeFunction {
		return variable.run(mut s, args)
	} else {
		s.throw('attempted to invoke non-function: ${func}')
	}
}

// invoke_list invokes the function with the provided name using the provided args, then returns the function's returned value.
// see also: invoke
@[inline]
pub fn (mut s Scope) invoke_list(func string, args []Value) Value {
	variable := s.get(func) or { s.throw('cannot invoke non-existent function `${func}`') }
	if variable is ValueFunction {
		mut func_args := map[string]Value{}
		for i, value in args {
			func_args[variable.args[i]] = value
		}
		return variable.run(mut s, func_args)
	} else if variable is ValueNativeFunction {
		mut func_args := map[string]Value{}
		for i, value in args {
			func_args[variable.args[i]] = value
		}
		return variable.run(mut s, func_args)
	} else {
		s.throw('attempted to invoke non-function: ${func}')
	}
}

// invoke_eval invokes the provided function using the provided args, then returns the function's returned value.
// see also: invoke, eval_function, eval_function_args
@[inline]
fn (mut s Scope) invoke_eval(func &INode, args map[string]Value) Value {
	variable := s.eval(func)
	if variable is ValueFunction {
		return variable.run(mut s, args)
	} else if variable is ValueNativeFunction {
		return variable.run(mut s, args)
	} else {
		s.throw('attempted to invoke non-function: ${func}')
	}
}

// eval_function_args evaluates each argument provided in the `ast.NodeInvoke` and returns them, but does not invoke the function.
@[inline]
fn (mut s Scope) eval_function_args(func Value, node &ast.NodeInvoke) map[string]Value {
	mut args := map[string]Value{}
	if func is ValueFunction {
		if node.args.len != func.args.len {
			s.throw('${node.args.len} arguments provided but ${func.args.len} are needed')
		}
		for index, arg in func.args {
			args[arg] = s.eval(node.args[index])
		}
	} else if func is ValueNativeFunction {
		if node.args.len != func.args.len {
			s.throw('${node.args.len} arguments provided but ${func.args.len} are needed. provided: ${node.args}')
		}
		for index, arg in func.args {
			args[arg] = s.eval(node.args[index])
		}
	} else {
		s.throw('attempted to eval arguments for non-function: ${func}')
	}

	return args
}

// invoke_node invokes the given `ast.NodeInvoke`, then returns the function's returned value.
@[inline]
fn (mut s Scope) invoke_node(node &ast.NodeInvoke) Value {
	variable := s.eval(node.func)
	args := s.eval_function_args(variable, node)
	return s.invoke_eval(node.func, args)
}

// eval_operator_value evaluates and returns the resulting `Value`.
pub fn (mut s Scope) eval_operator_value(kind ast.Operator, left Value, right Value) Value {
	match kind {
		// vfmt off
		.eq { return Value(left == right) }
		.neq { return Value(left != right) }
		.gteq { return Value((left as f64) >= (right as f64)) }
		.lteq { return Value((left as f64) <= (right as f64)) }
		.gt { return Value((left as f64) > (right as f64)) }
		.lt { return Value((left as f64) < (right as f64)) }
		.and { return Value((left as bool) && (right as bool)) }
		.or { return Value((left as bool) || (right as bool)) }
		.shift_right { return Value(f64(int(left as f64) >> int(right as f64))) }
		.shift_left { return Value(f64(int(left as f64) << int(right as f64))) }
		.bit_and { return Value(f64(int(left as f64) & int(right as f64))) }
		.bit_xor { return Value(f64(int(left as f64) ^ int(right as f64))) }
		.bit_or { return Value(f64(int(left as f64) | int(right as f64))) }
		.add { return Value((left as f64) + (right as f64)) }
		.sub { return Value((left as f64) - (right as f64)) }
		.div { return Value((left as f64) / (right as f64)) }
		.mul { return Value((left as f64) * (right as f64)) }
		.mod { return Value(f64(int(left as f64) % int(right as f64))) }
		// vfmt on
		else {
			s.throw('eval_operator_value() given an invalid kind (${kind}). This error should never happen, please report it.')
		}
	}
	s.throw('eval_operator_value() given an invalid kind (${kind}). This error should never happen, please report it.')
}

// eval_operator evaluates and returns the resulting `Value` from the given node.
@[inline]
fn (mut s Scope) eval_operator(node &ast.NodeOperator) Value {
	if node.kind != .pipe && node.kind != .dot && node.kind != .assign {
		return s.eval_operator_value(node.kind, s.eval(node.left), s.eval(node.right))
	}
	match node.kind {
		.pipe {
			return s.pipe(s.eval(node.left), node.right)
		}
		.dot {
			return s.eval_dots(node)
		}
		.assign {
			value := s.eval(node.right)
			if node.left is ast.NodeId {
				s.set(node.left.value, value)
			} else if node.left is ast.NodeString {
				s.set(node.left.value, value)
			} else if node.left is ast.NodeOperator && node.left.kind == .dot {
				dots := s.resolve_dots(node.left)
				s.set_nested(dots, value)
			} else {
				s.throw('assignment operator must have an identifier or string on the left.')
			}
			return value
		}
		else {
			s.throw('eval_operator() given a NodeOperator with an invalid kind (${node.kind}). This error should never happen, please report it.')
		}
	}
	s.throw('eval_operator() given a NodeOperator with an invalid kind (${node.kind}). This error should never happen, please report it.')
}

@[params]
pub struct EvalDotsParams {
pub:
	pipe_in ?Value
}

// eval_dots evaluates a series of nested dot operators, invoking the last one if it is an `ast.NodeInvoke`.
@[inline]
fn (mut s Scope) eval_dots(node &ast.NodeOperator, params EvalDotsParams) Value {
	left := s.eval(node.left)

	name := if node.right is ast.NodeId {
		node.right.value
	} else if node.right is ast.NodeString {
		node.right.value
	} else if node.right is ast.NodeInvoke {
		if left is map[string]Value {
			mut name := 'lambda'
			variable := if node.right.func is ast.NodeId {
				name = node.right.func.value
				if name[0] == `@` {
					name = name[1..]
				}
				left[name] or { s.throw('unknown variable (eval_dots on NodeInvoke): ${name}') }
			} else if node.right.func is ast.NodeString {
				name = node.right.func.value
				if name[0] == `@` {
					name = name[1..]
				}
				left[name] or { s.throw('unknown variable (eval_dots on NodeInvoke): ${name}') }
			} else {
				s.throw('cannot get function `${node.right.func}` on right side of dot operator (.)')
			}
			if params.pipe_in != none {
				mut args := []Value{}
				args << params.pipe_in
				for arg in node.right.args {
					args << s.eval(arg)
				}
				return s.eval_function_list_args(variable, args)
			} else {
				args := s.eval_function_args(variable, node.right)
				return s.eval_function(variable, args)
			}
		}
		s.throw('cannot use dot operator (.) on object `${left}`')
	} else if node.right is ast.NodeOperator {
		dotted := s.eval_dots(ast.NodeOperator{
			line:   node.left.line
			column: node.left.column
			left:   node.left
			right:  node.right.left
		})
		return s.eval_operator_value(node.right.kind, dotted, s.eval(node.right.right))
	} else {
		s.throw('eval_dots: expected identifier or string but got `${node.right}`')
	}

	if left is map[string]Value {
		return left[name] or { s.throw('failed to get `${name}`') }
	} else {
		s.throw('cannot use dot operator on non-table types.')
	}
}

// resolve_dots gets a list of each identifier/string in a series of dot operators.
@[inline]
fn (mut s Scope) resolve_dots(node &ast.NodeOperator) []string {
	mut dots := []string{}
	dots << if node.left is ast.NodeId {
		[node.left.value]
	} else if node.left is ast.NodeString {
		[node.left.value]
	} else if node.left is ast.NodeOperator && node.left.kind == .dot {
		s.resolve_dots(node.left)
	} else {
		s.throw('cannot resolve dots for ${node}')
	}
	dots << if node.right is ast.NodeId {
		[node.right.value]
	} else if node.right is ast.NodeString {
		[node.right.value]
	} else if node.right is ast.NodeOperator && node.right.kind == .dot {
		s.resolve_dots(node.right)
	} else {
		s.throw('cannot resolve dots for ${node}')
	}
	return dots
}

// set_nested follows the list of identifiers and sets the last one to the given value.
// see resolve_dots for an example usage.
@[inline]
pub fn (mut s Scope) set_nested(dots []string, value Value) {
	mut table := unsafe { &s.variables }
	for i in 0 .. dots.len - 1 {
		mut x := table.get(dots[i], s) as map[string]Value
		table = &x
	}
	unsafe {
		table[dots[dots.len - 1]] = value
	}
}

// pipe pipes the given value (`to_pipe`) into `pipe_into`, invoking it with `to_pipe` as the first argument.
@[inline]
fn (mut s Scope) pipe(to_pipe Value, pipe_into &INode) Value {
	if pipe_into is ast.NodeOperator {
		if pipe_into.kind == .pipe {
			// if we are piping into a pipe, we should evaluate the left expression, then pass that into the next
			return s.pipe(s.pipe(to_pipe, pipe_into.left), pipe_into.right)
		} else if pipe_into.kind == .dot {
			return s.eval_dots(pipe_into, pipe_in: to_pipe)
		}
	}

	if pipe_into !is ast.NodeInvoke {
		s.throw('cannot pipe into a non-function')
	}
	func := pipe_into as ast.NodeInvoke
	variable := s.eval(func.func)

	mut args := map[string]Value{}
	if variable is ValueFunction {
		if func.args.len + 1 != variable.args.len {
			s.throw('${func.args.len + 1} (+1 from pipe) arguments provided but ${variable.args.len} are needed')
		}
		args[variable.args[0]] = to_pipe
		for index, arg in variable.args[1..] {
			args[arg] = s.eval(func.args[index])
		}
	} else if variable is ValueNativeFunction {
		if func.args.len + 1 != variable.args.len {
			s.throw('${func.args.len} arguments provided but ${variable.args.len} are needed. provided: ${func.args} (+1 from pipe)')
		}
		args[variable.args[0]] = to_pipe
		for index, arg in variable.args[1..] {
			args[arg] = s.eval(func.args[index])
		}
	} else {
		s.throw('attempted to invoke non-function: ${func.func}')
	}

	return s.invoke_eval(func.func, args)
}

// import imports the given module (`mod`), returning it.
@[inline]
pub fn (mut s Scope) import(mod string) Value {
	return s.interpreter.import(mut s, mod)
}

// has_own returns true if the given variable exists in this scope (disregarding parent scopes).
// see also: has
@[inline]
pub fn (s &Scope) has_own(variable string) bool {
	return variable in s.variables
}

// has_own returns true if the given variable exists in this scope OR in parent scopes.
// see also: has_own
@[inline]
pub fn (s &Scope) has(variable string) bool {
	return variable in s.variables || (s.parent != unsafe { nil } && s.parent.has(variable))
}

// scope_of gets a pointer to the first scope containing the given variable.
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

// get gets the value with the provided variable name from this scope OR from parent scopes.
// see also: get_own
@[inline]
pub fn (s &Scope) get(variable string) ?Value {
	if variable in s.variables {
		return s.variables[variable] or {
			s.throw('failed to get a variable that... exists? this should never happen, please report this error')
		}
	} else if s.parent != unsafe { nil } {
		return s.parent.get(variable)
	} else {
		return none
	}
}

// get_ptr gets a pointer to the value with the provided variable name from this scope OR from parent scopes.
// see also: get
@[inline]
pub fn (s &Scope) get_ptr(variable string) ?&Value {
	if variable in s.variables {
		return &(s.variables[variable] or {
			s.throw('failed to get a variable that... exists? this should never happen, please report this error')
		})
	} else if s.parent != unsafe { nil } {
		return s.parent.get_ptr(variable)
	} else {
		return none
	}
}

// get_own gets the value with the provided variable name from this scope (disregarding parent scopes).
// see also: get
@[inline]
pub fn (s &Scope) get_own(variable string) ?Value {
	if variable in s.variables {
		return s.variables[variable] or {
			s.throw('uhh, i do not even know what this error would be caused by. just... report it please.')
		}
	} else {
		return none
	}
}

// get_own_ptr gets a pointer to the value with the provided variable name from this scope (disregarding parent scopes).
// see also: get_own
@[inline]
pub fn (s &Scope) get_own_ptr(variable string) ?Value {
	if variable in s.variables {
		// return &(s.variables[variable] or {
		// 	s.throw('uhh, i do not even know what this error would be caused by. just... report it please.')
		// })
		return s.variables[variable] or {
			s.throw('uhh, i do not even know what this error would be caused by. just... report it please.')
		}
	} else {
		return none
	}
}

// new creates a new variable in the current scope, throws an error if the variable already exists in the current scope.
@[inline]
pub fn (mut s Scope) new(variable string, value Value) {
	// we use has_own instead of has so that people can make variables with the same name in child scopes
	if s.has_own(variable) {
		s.throw('cannot create a new variable that already exists: ${variable}')
	} else {
		s.variables[variable] = value
	}
}

// set sets the value of an existing variable in this scope or in a parent scope.
@[inline]
pub fn (mut s Scope) set(variable string, value Value) {
	mut scope := s.scope_of(variable) or {
		s.throw('cannot set a non-existent variable: ${variable}')
	}
	scope.variables[variable] = value
}

// make_child makes a child scope, then returns it.
@[inline]
pub fn (s &Scope) make_child() Scope {
	child := Scope{
		interpreter: s.interpreter
		parent:      s
		file:        s.file
	}
	return child
}

// Scope.new creates a new scope for the given interpreter, then returns it.
@[inline]
pub fn Scope.new(i &Interpreter, file string) Scope {
	return Scope{
		interpreter: i
		parent:      unsafe { nil }
		file:        file
	}
}
