require "./spec_helper"

describe String do
  it "converts a hex string to Bytes" do
    "abc".hex_to_bytes.should eq(([10, 188] of UInt8).to_bytes)
    "abc5".hex_to_bytes.should eq(([171, 197] of UInt8).to_bytes)
  end

  it "converts a hex string to a BigInt" do
    "abc".hex_to_bigint.should eq(BigInt.new(10*16*16 + 11*16 + 12))
  end
end

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