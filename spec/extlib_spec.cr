require "./spec_helper"

describe Bytes do
  it "converts to hex" do
    bytes = ([12, 45] of UInt8).to_bytes
    bytes.to_hex.should eq("0c2d")
  end
end

describe Random do
  it "generates random UInt128 numbers" do
    Random.new(5).rand(UInt128).should eq(334081043640913887584633984963796051327_u128)
  end
end

describe String do
  it "converts a hex string to Bytes" do
    "abc".hex_to_bytes.should eq(([10, 188] of UInt8).to_bytes)
    "abc5".hex_to_bytes.should eq(([171, 197] of UInt8).to_bytes)
  end

  it "converts a hex string to a BigInt" do
    "abc".hex_to_bigint.should eq(BigInt.new(10*16*16 + 11*16 + 12))
    "abcd".hex_to_bigint.should eq(BigInt.new(10*16**3 + 11*16**2 + 12*16 + 13))
  end
end

describe UInt128 do
  it "UInt128.bytes returns a Slice(UInt8) where the 0th element is the low-order byte of the u128 and the 15th element is the high order byte of the u128" do
    uint = 0b0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_0000_0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_0111_u128

    uint_byte_array_from_msb_to_lsb = [0b00010010_u8, 0b00110100_u8, 0b01010110_u8, 0b01111000_u8, 0b10011010_u8, 0b10111100_u8, 0b11011110_u8, 0b11110000_u8, 0b00010010_u8, 0b00110100_u8, 0b01010110_u8, 0b01111000_u8, 0b10011010_u8, 0b10111100_u8, 0b11011110_u8, 0b11110111_u8] of UInt8

    UInt128.bytes(pointerof(uint)).to_a.should eq(uint_byte_array_from_msb_to_lsb.reverse)
  end

  it "UInt128.bytes and UInt128.from_bytes are the inverse of one another" do
    r = Random.new(5)

    1000.times do
      u128 = UInt128.rand(r)

      bytes = UInt128.bytes(pointerof(u128))
      reconstructed_u128 = UInt128.from_bytes(bytes)

      reconstructed_u128.should eq(u128)
    end
  end
end

describe UUID do
  it "UUID.from_u128 converts uint128 to UUID with a nil version and nil variant" do
    uint = 0b0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_0000_0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_0111_u128
    # pos       1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32
    # value     1    2    3    4    5    6    7    8    9   10   11   12   13   14   15    0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15    7
    # hex       1    2    3    4    5    6    7    8    9    a    b    c    d    e    f    0    1    2    3    4    5    6    7    8    9    a    b    c    d    e    f    7

    uuid = UUID.from_u128(uint, nil, nil)

    uuid.to_s.should eq("12345678-9abc-def0-1234-56789abcdef7")   # this is a properly hyphenated version of the expected_hexstring
  end

  it "UUID.from_u128 converts uint128 to UUID with a v4 version and RFC4122 variant" do
    uint = 0b0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_0000_0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_0111_u128
    # pos       1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32
    # value     1    2    3    4    5    6    7    8    9   10   11   12   13   14   15    0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15    7
    # hex       1    2    3    4    5    6    7    8    9    a    b    c    d    e    f    0    1    2    3    4    5    6    7    8    9    a    b    c    d    e    f    7
    # binary:   00010010_00110100_01010110_01111000_10011010_10111100_11011110_11110000_00010010_00110100_01010110_01111000_10011010_10111100_11011110_11110111

    # UUID version 4 (M = 0x4), variant 1 (N = 0b10xx)

    # assuming the ordering of the bytes is from most significant byte to least significant byte (counting from the left)
    # expected_uuid = uint &
    # # zero out the 13th hex digit (high order 4 bits of the 7th byte) and two most significant bits in the 17th hex digit (high order 2 bits of the 9th byte)
    # 0b11111111_11111111_11111111_11111111_11111111_11111111_00001111_11111111_00111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_u128 |
    # # set v4 version by setting 13th hex digit to 4
    # 0b00000000_00000000_00000000_00000000_00000000_00000000_01000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_u128 |
    # # set the variant to DCE 1.1, ISO/IEC 11578:1996 by setting the two most significant bits in the 17th hex digit to 0b10
    # 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_u128
    # expected_uuid =
    # 00010010_00110100_01010110_01111000_10011010_10111100_01001110_11110000_10010010_00110100_01010110_01111000_10011010_10111100_11011110_11110111

    expected_uuid_byte_array_from_msb_to_lsb = [0b00010010_u8, 0b00110100_u8, 0b01010110_u8, 0b01111000_u8, 0b10011010_u8, 0b10111100_u8, 0b11011110_u8, 0b10110000_u8, 0b00010010_u8, 0b01000100_u8, 0b01010110_u8, 0b01111000_u8, 0b10011010_u8, 0b10111100_u8, 0b11011110_u8, 0b11110111_u8] of UInt8


    uuid_variant = UUID::Variant::RFC4122
    uuid_version = UUID::Version::V4
    uuid = UUID.from_u128(uint, uuid_version, uuid_variant)

    uuid.to_s.should eq("12345678-9abc-4ef0-9234-56789abcdef7")   # this is a properly hyphenated version of the expected_hexstring
  end

  it "UUID.from_u128_inverted converts uint128 to UUID with a nil version and nil variant" do
    uint = 0b0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_0000_0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_0111_u128
    # pos       1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32
    # value     1    2    3    4    5    6    7    8    9   10   11   12   13   14   15    0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15    7
    # hex       1    2    3    4    5    6    7    8    9    a    b    c    d    e    f    0    1    2    3    4    5    6    7    8    9    a    b    c    d    e    f    7

    uuid = UUID.from_u128_inverted(uint, nil, nil)

    # test #1 - internal bytes representation of UUID represents the 0th byte as the low-order byte of the u128 and the 15th byte as the high order byte of the u128
    UInt128.from_bytes(uuid.bytes).should eq(uint)
    UInt128.from_bytes(uuid.bytes.to_slice).should eq(uint)

    # test #2 - UUID hexstring represents the UUID's internal byte sequence as a hex encoded string
    expected_hexstring = UInt128.bytes(pointerof(uint)).hexstring       # expected_hexstring = "f7debc9a78563412f0debc9a78563412"
    uuid.hexstring.should eq(expected_hexstring)

    # test #3 - UUID hexstring is propertly formatted
    uuid.to_s.should eq("f7debc9a-7856-3412-f0de-bc9a78563412")   # this is a properly hyphenated version of the expected_hexstring
  end

  it "UUID.from_u128_inverted converts uint128 to UUID with a v4 version and RFC4122 variant" do
    uint = 0b0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_0000_0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_0111_u128
    # pos       1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32
    # value     1    2    3    4    5    6    7    8    9   10   11   12   13   14   15    0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15    7
    # hex       1    2    3    4    5    6    7    8    9    a    b    c    d    e    f    0    1    2    3    4    5    6    7    8    9    a    b    c    d    e    f    7
    # binary:   00010010_00110100_01010110_01111000_10011010_10111100_11011110_11110000_00010010_00110100_01010110_01111000_10011010_10111100_11011110_11110111

    # UUID version 4 (M = 0x4), variant 1 (N = 0b10xx)

    # assuming the ordering of the bytes is from most significant byte to least significant byte (counting from the left)
    # expected_uuid = uint &
    # # zero out the 13th hex digit (high order 4 bits of the 7th byte) and two most significant bits in the 17th hex digit (high order 2 bits of the 9th byte)
    # 0b11111111_11111111_11111111_11111111_11111111_11111111_00001111_11111111_00111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_u128 |
    # # set v4 version by setting 13th hex digit to 4
    # 0b00000000_00000000_00000000_00000000_00000000_00000000_01000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_u128 |
    # # set the variant to DCE 1.1, ISO/IEC 11578:1996 by setting the two most significant bits in the 17th hex digit to 0b10
    # 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_u128
    # expected_uuid =
    # 00010010_00110100_01010110_01111000_10011010_10111100_01001110_11110000_10010010_00110100_01010110_01111000_10011010_10111100_11011110_11110111

    # assuming the ordering of the bytes is from least significant byte to most significant byte (counting from the right)
    expected_uuid = uint &
    # zero out the 13th hex digit (high order 4 bits of the 7th byte) and two most significant bits in the 17th hex digit (high order 2 bits of the 9th byte)
    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_00111111_11111111_00001111_11111111_11111111_11111111_11111111_11111111_11111111_u128 |
    # set v4 version by setting high order 4 bits of the 7th byte to 4
    0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_01000000_00000000_00000000_00000000_00000000_00000000_00000000_u128 |
    # set the variant to DCE 1.1, ISO/IEC 11578:1996 by setting the high order 2 bits of the 9th byte 0b10
    0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_u128
    # expected_uuid =
    # 00010010_00110100_01010110_01111000_10011010_10111100_11011110_10110000_00010010_01000100_01010110_01111000_10011010_10111100_11011110_11110111

    expected_uuid_byte_array_from_msb_to_lsb = [0b00010010_u8, 0b00110100_u8, 0b01010110_u8, 0b01111000_u8, 0b10011010_u8, 0b10111100_u8, 0b11011110_u8, 0b10110000_u8, 0b00010010_u8, 0b01000100_u8, 0b01010110_u8, 0b01111000_u8, 0b10011010_u8, 0b10111100_u8, 0b11011110_u8, 0b11110111_u8] of UInt8


    uuid_variant = UUID::Variant::RFC4122
    uuid_version = UUID::Version::V4
    uuid = UUID.from_u128_inverted(uint, uuid_version, uuid_variant)

    # test #1 - internal bytes representation of UUID represents the 0th byte as the low-order byte of the u128 and the 15th byte as the high order byte of the u128
    # expected_uuid_byte_array_from_msb_to_lsb.map{|b| b.to_s(2, precision: 8) }.join("_").should eq("fooo")
    # uuid.bytes.to_a.reverse.map{|b| b.to_s(2, precision: 8) }.join("_").should eq(expected_uuid_byte_array_from_msb_to_lsb)
    uuid.bytes.to_a.should eq(expected_uuid_byte_array_from_msb_to_lsb.reverse)

    UInt128.from_bytes(uuid.bytes).should eq(expected_uuid)
    UInt128.from_bytes(uuid.bytes.to_slice).should eq(expected_uuid)

    # test #2 - UUID hexstring represents the UUID's internal byte sequence as a hex encoded string
    expected_hexstring = UInt128.bytes(pointerof(expected_uuid)).hexstring       # expected_hexstring = "f7debc9a78564412b0debc9a78563412"
    uuid.hexstring.should eq(expected_hexstring)

    # test #3 - UUID hexstring is propertly formatted
    uuid.to_s.should eq("f7debc9a-7856-4412-b0de-bc9a78563412")   # this is a properly hyphenated version of the expected_hexstring
  end

  it "guarantees that .from_u128 and #to_u128 are inverse operations" do
    uint = 0b0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_0000_0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_0111_u128
    # pos       1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32
    # value     1    2    3    4    5    6    7    8    9   10   11   12   13   14   15    0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15    7
    # hex       1    2    3    4    5    6    7    8    9    a    b    c    d    e    f    0    1    2    3    4    5    6    7    8    9    a    b    c    d    e    f    7
    uuid = UUID.from_u128(uint, nil, nil)
    uuid.to_s.should eq("12345678-9abc-def0-1234-56789abcdef7")   # this is a properly hyphenated version of the expected_hexstring
    uuid.to_u128.should eq(uint)
  end

  it "guarantees that .from_u128_inverted and #to_u128_inverted are inverse operations" do
    uint = 0b0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_0000_0001_0010_0011_0100_0101_0110_0111_1000_1001_1010_1011_1100_1101_1110_1111_0111_u128
    # pos       1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32
    # value     1    2    3    4    5    6    7    8    9   10   11   12   13   14   15    0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15    7
    # hex       1    2    3    4    5    6    7    8    9    a    b    c    d    e    f    0    1    2    3    4    5    6    7    8    9    a    b    c    d    e    f    7
    uuid = UUID.from_u128_inverted(uint, nil, nil)
    # uuid.to_s.should eq("12345678-9abc-def0-1234-56789abcdef7")   # this is a properly hyphenated version of the expected_hexstring
    uuid.to_u128_inverted.should eq(uint)
  end
end
