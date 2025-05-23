module std::io;

struct ByteReader (InStream)
{
	char[] bytes;
	usz index;
}

fn usz ByteReader.len(&self) @dynamic
{
	return self.bytes.len;
}

fn ByteReader* ByteReader.init(&self, char[] bytes)
{
	*self = { .bytes = bytes };
	return self;
}

fn usz? ByteReader.read(&self, char[] bytes) @dynamic
{
	if (self.index >= self.bytes.len) return io::EOF?;
	usz len = min(self.bytes.len - self.index, bytes.len);
	if (len == 0) return 0;
	mem::copy(bytes.ptr, &self.bytes[self.index], len);
	self.index += len;
	return len;
}

fn char? ByteReader.read_byte(&self) @dynamic
{
	if (self.index >= self.bytes.len) return io::EOF?;
	return self.bytes[self.index++];
}

fn void? ByteReader.pushback_byte(&self) @dynamic
{
	if (!self.index) return INVALID_PUSHBACK?;
	self.index--;
}

fn usz? ByteReader.seek(&self, isz offset, Seek seek) @dynamic
{
	isz new_index;
	switch (seek)
	{
		case SET: new_index = offset;
		case CURSOR: new_index = self.index + offset;
		case END: new_index = self.bytes.len + offset;
	}
	if (new_index < 0) return INVALID_POSITION?;
	self.index = new_index;
	return new_index;
}

fn usz? ByteReader.write_to(&self, OutStream writer) @dynamic
{
	if (self.index >= self.bytes.len) return 0;
	usz written = writer.write(self.bytes[self.index..])!;
	self.index += written;
	assert(self.index <= self.bytes.len);
	return written;
}

fn usz? ByteReader.available(&self) @inline @dynamic
{
	return max(0, self.bytes.len - self.index);
}