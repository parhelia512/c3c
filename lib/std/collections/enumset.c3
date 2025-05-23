// Copyright (c) 2021-2024 Christoffer Lerno. All rights reserved.
// Use of self source code is governed by the MIT license
// a copy of which can be found in the LICENSE_STDLIB file.

<*
 @require Enum.kindof == TypeKind.ENUM : "Only enums may be used with an enumset"
*>
module std::collections::enumset{Enum};
import std::io;

const ENUM_COUNT @private = Enum.values.len;
alias EnumSetType @private = $typefrom(type_for_enum_elements(ENUM_COUNT));

const IS_CHAR_ARRAY = ENUM_COUNT > 128;
typedef EnumSet (Printable) = EnumSetType;

fn void EnumSet.add(&self, Enum v)
{
	$if IS_CHAR_ARRAY:
		(*self)[(usz)v.ordinal / 8] |= (char)(1u << ((usz)v.ordinal % 8));
	$else
		*self = (EnumSet)((EnumSetType)*self | 1u << (EnumSetType)v.ordinal);
	$endif
}

fn void EnumSet.clear(&self)
{
	$if IS_CHAR_ARRAY:
		*self = {};
	$else
		*self = 0;
	$endif
}

fn bool EnumSet.remove(&self, Enum v)
{
	$if IS_CHAR_ARRAY:
		if (!self.has(v) @inline) return false;
		(*self)[(usz)v.ordinal / 8] &= (char)~(1u << ((usz)v.ordinal % 8));
		return true;
	$else
		EnumSetType old = (EnumSetType)*self;
		EnumSetType new = old & ~(1u << (EnumSetType)v.ordinal);
		*self = (EnumSet)new;
		return old != new;
	$endif
}

fn bool EnumSet.has(&self, Enum v)
{
	$if IS_CHAR_ARRAY:
		return (bool)(((*self)[(usz)v.ordinal / 8] << ((usz)v.ordinal % 8)) & 0x01);
	$else
		return ((EnumSetType)*self & (1u << (EnumSetType)v.ordinal)) != 0;
	$endif
}

fn void EnumSet.add_all(&self, EnumSet s)
{
	$if IS_CHAR_ARRAY:
		foreach (i, c : s) (*self)[i] |= c;
	$else
		*self = (EnumSet)((EnumSetType)*self | (EnumSetType)s);
	$endif
}

fn void EnumSet.retain_all(&self, EnumSet s)
{
	$if IS_CHAR_ARRAY:
		foreach (i, c : s) (*self)[i] &= c;
	$else
		*self = (EnumSet)((EnumSetType)*self & (EnumSetType)s);
	$endif
}

fn void EnumSet.remove_all(&self, EnumSet s)
{
	$if IS_CHAR_ARRAY:
		foreach (i, c : s) (*self)[i] &= ~c;
	$else
		*self = (EnumSet)((EnumSetType)*self & ~(EnumSetType)s);
	$endif
}

fn EnumSet EnumSet.and_of(&self, EnumSet s)
{
	$if IS_CHAR_ARRAY:
		EnumSet copy = *self;
		copy.retain_all(s);
		return copy;
	$else
		return (EnumSet)((EnumSetType)*self & (EnumSetType)s);
	$endif
}

fn EnumSet EnumSet.or_of(&self, EnumSet s)
{
	$if IS_CHAR_ARRAY:
		EnumSet copy = *self;
		copy.add_all(s);
		return copy;
	$else
		return (EnumSet)((EnumSetType)*self | (EnumSetType)s);
	$endif
}


fn EnumSet EnumSet.diff_of(&self, EnumSet s)
{
	$if IS_CHAR_ARRAY:
		EnumSet copy = *self;
		copy.remove_all(s);
		return copy;
	$else
		return (EnumSet)((EnumSetType)*self & ~(EnumSetType)s);
	$endif
}

fn EnumSet EnumSet.xor_of(&self, EnumSet s)
{
	$if IS_CHAR_ARRAY:
		EnumSet copy = *self;
		foreach (i, c : s) copy[i] ^= c;
		return copy;
	$else
		return (EnumSet)((EnumSetType)*self ^ (EnumSetType)s);
	$endif
}

fn usz? EnumSet.to_format(&set, Formatter* formatter) @dynamic
{
	usz n = formatter.print("[")!;
	bool found;
	foreach (value : Enum.values)
	{
		if (!set.has(value)) continue;
		if (found) n += formatter.print(", ")!;
		found = true;
		n += formatter.printf("%s", value)!;
	}
	n += formatter.print("]")!;
	return n;
}

macro typeid type_for_enum_elements(usz $elements) @local
{
	$switch:
		$case ($elements > 128):
			return char[($elements + 7) / 8].typeid;
		$case ($elements > 64):
			return uint128.typeid;
		$case ($elements > 32 || $$C_INT_SIZE > 32):
			return ulong.typeid;
		$case ($elements > 16 || $$C_INT_SIZE > 16):
			return uint.typeid;
		$case ($elements > 8 || $$C_INT_SIZE > 8):
			return ushort.typeid;
		$default:
			return char.typeid;
	$endswitch
}