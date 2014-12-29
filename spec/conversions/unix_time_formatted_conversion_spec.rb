# encoding: ascii-8bit

# Copyright 2014 Ball Aerospace & Technologies Corp.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt

require 'spec_helper'
require 'cosmos/conversions/unix_time_formatted_conversion'
require 'cosmos/packets/packet'

module Cosmos

  describe UnixTimeFormattedConversion do

    describe "initialize" do
      it "should initialize converted_type and converted_bit_size" do
        gc = UnixTimeFormattedConversion.new('TIME')
        gc.converted_type.should eql :STRING
        gc.converted_bit_size.should eql 0
      end
    end

    describe "call" do
      it "should return the formatted packet time based on seconds" do
        gc = UnixTimeFormattedConversion.new('TIME')
        packet = Packet.new("TGT","PKT")
        packet.append_item("TIME",32,:UINT)
        packet.write("TIME",Time.new(2020,1,31,12,15,30).to_f)
        gc.call(nil,packet,packet.buffer).should eql "2020/01/31 12:15:30.000"
      end

      it "should return the formatted packet time based on seconds and microseconds" do
        gc = UnixTimeFormattedConversion.new('TIME','TIME_US')
        packet = Packet.new("TGT","PKT")
        packet.append_item("TIME",32,:UINT)
        packet.write("TIME",Time.new(2020,1,31,12,15,30).to_f)
        packet.append_item("TIME_US",32,:UINT)
        packet.write("TIME_US",500000)
        gc.call(nil,packet,packet.buffer).should eql "2020/01/31 12:15:30.500"
      end

      it "should complain if the seconds item doesn't exist" do
        gc = UnixTimeFormattedConversion.new('TIME')
        packet = Packet.new("TGT","PKT")
        expect { gc.call(nil,packet,packet.buffer) }.to raise_error("Packet item 'TGT PKT TIME' does not exist")
      end

      it "should complain if the microseconds item doesn't exist" do
        gc = UnixTimeFormattedConversion.new('TIME','TIME_US')
        packet = Packet.new("TGT","PKT")
        packet.append_item("TIME",32,:UINT)
        expect { gc.call(nil,packet,packet.buffer) }.to raise_error("Packet item 'TGT PKT TIME_US' does not exist")
      end

    end

    describe "to_s" do
      it "should return the seconds conversion" do
        gc = UnixTimeFormattedConversion.new('TIME')
        gc.to_s.should eql "Time.at(packet.read('TIME', :RAW, buffer), 0).formatted"
      end

      it "should return the microseconds conversion" do
        gc = UnixTimeFormattedConversion.new('TIME','TIME_US')
        gc.to_s.should eql "Time.at(packet.read('TIME', :RAW, buffer), packet.read('TIME_US', :RAW, buffer)).formatted"
      end
    end
  end
end

