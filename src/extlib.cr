require "big"
require "random"
require "uuid"

module Extlib
  VERSION = "0.1.0"

  # TODO: Put your code here
end

class Period
  property years
  property months
  property days
  property hours
  property minutes
  property seconds
  property milliseconds

  def initialize(years, months, days, hours, minutes, seconds, milliseconds)
    @years = years
    @months = months
    @days = days
    @hours = hours
    @minutes = minutes
    @seconds = seconds
    @milliseconds = milliseconds
  end
end

class Array(T)
  # Example:
  # puts [1,2,3,4].fold_right(5) {|memo, num| memo * 10 + num }    # prints "54321"
  def fold_right(memo : A, &blk : (A, T) -> A) forall A
    reverse_each do |elem|
      memo = yield memo, elem
    end
    memo
  end

  # Example:
  # puts [1,2,3,4].fold_right(5) {|memo, num, i| puts("#{i} -> #{num}"); memo * 10 + num }
  # prints:
  # 3 -> 4
  # 2 -> 3
  # 1 -> 2
  # 0 -> 1
  # 54321
  def fold_right(memo : A, &blk : (A, T, Int32) -> A) forall A
    reverse_each_with_index do |elem, index|
      memo = yield memo, elem, index
    end
    memo
  end

  # Yields each element in this iterator together with its index.
  def reverse_each_with_index
    (size - 1).downto(0) do |index|
      yield unsafe_fetch(index), index
    end
  end

  # def to_bytes
  #   arr : Array(UInt8) = self
  #   Bytes.new(size) {|i| arr[i] }
  # end
  def to_bytes
    arr = self
    Bytes.new(size) {|i| arr[i].to_u8 }
  end
end

# monkey patch BigInt to introduce a new class method onto BigInt
struct BigInt
  # converts a slice of bytes in which bytes[0] is the low-order byte of the BigInt and bytes[15] is the high order byte
  # of the BigInt back into the corresponding BigInt
  # This method assumes `bytes` is little endian
  def self.from_bytes(bytes : Bytes | Array(UInt8)) : BigInt
    bytes.to_a.reverse.reduce(BigInt.new(0)) {|acc, byte| (acc << 8) | byte }
  end
end

module Random
  # Returns a random UInt128
  #
  # ```
  # rand(UInt128) # => {{values[0].id}}
  # ```
  def rand(type : UInt128.class) : UInt128
    UInt128.rand(self)
  end

  # Returns a StaticArray filled with random UInt128 values.
  #
  # ```
  # rand(StaticArray(UInt128, 4)) # => StaticArray[{{values.join(", ").id}}]
  # ```
  # def rand(type : StaticArray(UInt128, _).class)
  #   rand_type_from_bytes(type)
  # end
end

struct Slice(T)
  BYTE_TO_HEX_MAP = (0..255).each.with_index.map {|v, i| i.to_s(16).rjust(2, '0') }.to_a

  # assumes Slice(UInt8)
  def to_hex : String
    String.build do |str|
      each {|byte| str << BYTE_TO_HEX_MAP[byte] }
    end
  end
end

class String
  # converts hex string to Bytes in which the leftmost part of the string represents the most significant bytes and
  # the rightmost part of the string represents the least significant bytes
  # Returns Bytes object formatted in big endian if the byte sequence was considered a number - most significant byte in the lowest address and least significant byte in the largest address.
  def hex_to_bytes : Bytes
    str = if size.even?
      self
    else
      "0#{self}"
    end
    byte_count = str.size // 2
    Bytes.new(byte_count) do |i|
      j = i * 2
      str[j, 2].to_u8(16)
    end
  end

  def hex_to_bigint : BigInt
    hex_to_bytes_le = hex_to_bytes.reverse!
    BigInt.from_bytes(hex_to_bytes_le)
  end

  def to_period
    m = match(/((?<d>\d+)d)?(?<h>(\d+)h)?(?<m>(\d+)m)?/)
    Period.new(0, 0, m[:d], m[:h], m[:m], 0, 0)
  end
end

# monkey patch UInt128 to introduce a new class method onto UInt128
struct UInt128
  # converts the u128 into a slice of bytes in which bytes[0] is the low-order byte of the u128 and bytes[15] is the high order byte of the u128
  # Returns a Slice(UInt8) in little endian format.
  def self.bytes(u128_p : Pointer(UInt128)) : Slice(UInt8)
    u8_p = u128_p.as(UInt8*)
    u8_p.to_slice(16)     # bytes[0] is the low-order byte of the u128 and bytes[15] is the high order byte of the u128
  end

  # converts a slice of bytes in which bytes[0] is the low-order byte of the u128 and bytes[15] is the high order byte of the u128 back into the corresponding u128
  # Assumes `bytes` in little endian format.
  def self.from_bytes(bytes : Bytes | StaticArray(UInt8, 16)) : UInt128
    bytes.to_a.reverse.reduce(0_u128) {|acc, byte| (acc << 8) | byte }
  end

  def self.rand(random : Random = Random) : UInt128
    random.rand(UInt64).to_u128 << 64 | random.rand(UInt64)
  end
end

# monkey patch UUID to introduce a new class method onto UUID
struct UUID
  # Returns a UUID from a given u128
  # NOTE: The the most significant byte of the u128 is the most significant byte (left-most byte) of the UUID,
  #       and the least significant byte of the u128 is the least significant byte (right-most byte) of the UUID.
  def self.from_u128(u128 : UInt128, version : UUID::Version? = nil, variant : UUID::Variant? = nil) : UUID
    UUID.new(UInt128.bytes(pointerof(u128)).reverse!, variant, version)
  end

  # Returns a UUID from a given u128
  # NOTE: This encoding is called "inverted" because the the most significant byte of the u128 is the least significant byte (right-most byte) of the UUID
  #       and the least significant byte of the u128 is the most significant byte (left-most byte) of the UUID.
  def self.from_u128_inverted(u128 : UInt128, version : UUID::Version? = nil, variant : UUID::Variant? = nil) : UUID
    UUID.new(UInt128.bytes(pointerof(u128)), variant, version)
  end
end
