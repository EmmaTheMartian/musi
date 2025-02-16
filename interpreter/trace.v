module interpreter

pub struct Trace {
pub:
	file   string @[required]
	source string @[required]
	line   int    @[required]
	column int    @[required]
}
