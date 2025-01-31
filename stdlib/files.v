module stdlib

import interpreter { IFunctionValue, Scope, Value, ValueFunction, ValueNativeFunction }
import os

struct FileHandler {
mut:
	files map[u64]os.File
	next  u64
}

@[inline]
fn (mut fh FileHandler) open(scope &Scope, path string, mode string) u64 {
	if !os.exists(path) {
		scope.throw('open: file does not exist: `${path}`')
	}
	it := os.open_file(path, mode) or {
		scope.throw('failed to open file `${path}`')
	}
	fh.files[fh.next] = it
	$if debug {
		println('(debug) file_handler opened `${path}`@${fh.next}: ${it}')
	}
	fh.next++
	return fh.next - 1
}

@[inline]
fn (mut fh FileHandler) create(scope &Scope, path string) u64 {
	it := os.create(path) or {
		scope.throw('failed to create file `${path}`')
	}
	fh.files[fh.next] = it
	$if debug {
		println('(debug) file_handler created `${path}`@${fh.next}: ${it}')
	}
	fh.next++
	return fh.next - 1
}

__global file_handler = FileHandler{}

@[inline]
fn open(mut scope Scope) Value {
	path := scope.get_fn_arg[string]('path', 'open')
	mode := scope.get_fn_arg[string]('mode', 'open')
	// TODO: change to `u64` when i add that to `Value`
	return f64(file_handler.open(scope, path, mode))
}

@[inline]
fn create(mut scope Scope) Value {
	// TODO: change to `u64` when i add that to `Value`
	return f64(file_handler.create(scope, scope.get_fn_arg[string]('path', 'create')))
}

@[inline]
fn exists(mut scope Scope) Value {
	return os.exists(scope.get_fn_arg[string]('path', 'open'))
}

@[inline]
fn close(mut scope Scope) Value {
	mut file := file_handler.files[u64(scope.get_fn_arg[f64]('file', 'close'))] or {
		scope.throw('file pointer no longer exists.')
	}
	file.close()
	return interpreter.null_value
}

@[inline]
fn write(mut scope Scope) Value {
	mut file := file_handler.files[u64(scope.get_fn_arg[f64]('file', 'write'))] or {
		scope.throw('file pointer no longer exists.')
	}
	data := scope.get_fn_arg[string]('data', 'write')
	file.write_string(data) or {
		scope.throw('failed to write string to file. (v error: ${err})')
	}
	return interpreter.null_value
}

@[inline]
fn read(mut scope Scope) Value {
	file := file_handler.files[u64(scope.get_fn_arg[f64]('file', 'read'))] or {
		scope.throw('file pointer no longer exists.')
	}
	bytes := int(scope.get_fn_arg[f64]('bytes', 'read'))
	return file.read_bytes(bytes).bytestr()
}

@[inline]
fn filesize(mut scope Scope) Value {
	path := scope.get_fn_arg[string]('path', 'size')
	if !os.exists(path) {
		scope.throw('size: file does not exist: `${path}`')
	}
	return f64(os.file_size(path))
}

pub const files_module ={
	'open': Value(ValueNativeFunction{
		tracer: 'open'
		args: ['path', 'mode']
		code: open
	})
	'create': ValueNativeFunction{
		tracer: 'create'
		args: ['path']
		code: create
	}
	'exists': ValueNativeFunction{
		tracer: 'exists'
		args: ['path']
		code: exists
	}
	'close': ValueNativeFunction{
		tracer: 'close'
		args: ['file']
		code: close
	}
	'write': ValueNativeFunction{
		tracer: 'write'
		args: ['file', 'data']
		code: write
	}
	'read': ValueNativeFunction{
		tracer: 'read'
		args: ['file', 'bytes']
		code: read
	}
	'size': ValueNativeFunction{
		tracer: 'size'
		args: ['path']
		code: filesize
	}
}

@[inline]
pub fn apply_files(mut scope Scope) {
	scope.new('files', files_module)
}
