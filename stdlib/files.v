module stdlib

import interpreter { Scope, Value, ValueNativeFunction }
import os

@[inline]
fn files_open(mut scope Scope) Value {
	path := scope.get_fn_arg[string]('path', 'open')
	it := os.open(path) or { scope.throw('open: file does not exist: `${path}`') }
	return Value(voidptr(&it))
}

@[inline]
fn files_create(mut scope Scope) Value {
	path := scope.get_fn_arg[string]('path', 'create')
	it := os.create(path) or { scope.throw('create: filaed to create file: `${path}`') }
	return Value(voidptr(&it))
}

@[inline]
fn files_close(mut scope Scope) Value {
	mut file := unsafe { &os.File(scope.get_fn_arg[voidptr]('file', 'close')) }
	file.close()
	return interpreter.null_value
}

@[inline]
fn files_write(mut scope Scope) Value {
	mut file := unsafe { &os.File(scope.get_fn_arg[voidptr]('file', 'write')) }
	data := scope.get_fn_arg[string]('data', 'write')
	file.write_string(data) or { scope.throw('failed to write string to file. (v error: ${err})') }
	return interpreter.null_value
}

@[inline]
fn files_flush(mut scope Scope) Value {
	mut file := unsafe { &os.File(scope.get_fn_arg[voidptr]('file', 'flush')) }
	file.flush()
	return interpreter.null_value
}

@[inline]
fn files_getcursorpos(mut scope Scope) Value {
	mut file := unsafe { &os.File(scope.get_fn_arg[voidptr]('file', 'getcursorpos')) }
	return f64(file.tell() or { panic(err) })
}

@[inline]
fn files_setcursorpos(mut scope Scope) Value {
	mut file := unsafe { &os.File(scope.get_fn_arg[voidptr]('file', 'setcursorpos')) }
	pos := int(scope.get_fn_arg[f64]('pos', 'setcursorpos'))
	file.seek(pos, .start) or { panic(err) }
	return interpreter.null_value
}

@[inline]
fn files_offsetcursorpos(mut scope Scope) Value {
	mut file := unsafe { &os.File(scope.get_fn_arg[voidptr]('file', 'setcursorpos')) }
	pos := int(scope.get_fn_arg[f64]('pos', 'setcursorpos'))
	file.seek(pos, .current) or { panic(err) }
	return interpreter.null_value
}

@[inline]
fn files_read(mut scope Scope) Value {
	mut file := unsafe { &os.File(scope.get_fn_arg[voidptr]('file', 'read')) }
	bytes := int(scope.get_fn_arg[f64]('bytes', 'read'))
	return file.read_bytes(bytes).bytestr()
}

@[inline]
fn files_size(mut scope Scope) Value {
	of := scope.get_fn_arg_raw('of', 'size')
	if of is string {
		if !os.exists(of) {
			scope.throw('size: file does not exist: `${of}`')
		}
		return f64(os.file_size(of))
	} else if of is voidptr {
		mut file := unsafe { &os.File(of) }
		// calculate size of file
		start := file.tell() or { panic(err) }
		file.seek(0, .end) or { panic(err) }
		size := file.tell() or { panic(err) }
		file.seek(start, .start) or { panic(err) }
		return f64(size)
	} else {
		scope.throw('size: argument `of` must be a string or voidptr.')
	}
}

@[inline]
fn files_exists(mut scope Scope) Value {
	return os.exists(scope.get_fn_arg[string]('path', 'exists'))
}

pub const files_module = [
	ValueNativeFunction.new('open', ['path'], files_open),
	ValueNativeFunction.new('create', ['path'], files_create),
	ValueNativeFunction.new('close', ['file'], files_close),
	ValueNativeFunction.new('write', ['file', 'data'], files_write),
	ValueNativeFunction.new('flush', ['file'], files_flush),
	ValueNativeFunction.new('getcursorpos', ['file'], files_getcursorpos),
	ValueNativeFunction.new('setcursorpos', ['file', 'pos'], files_setcursorpos),
	ValueNativeFunction.new('offsetcursorpos', ['file', 'pos'], files_offsetcursorpos),
	ValueNativeFunction.new('read', ['file', 'bytes'], files_read),
	ValueNativeFunction.new('size', ['of'], files_size),
	ValueNativeFunction.new('exists', ['path'], files_exists),
]

// apply_files applies the file i/o module (`files`) to the given scope.
@[inline]
pub fn apply_files(mut scope Scope) {
	mut mod := map[string]Value{}
	for func in files_module {
		mod[func.tracer.source] = func
	}
	scope.new('files', mod)
}
