# encoding: ascii-8bit

# Copyright 2014 Ball Aerospace & Technologies Corp.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt

require 'spec_helper'
require 'cosmos'
require 'cosmos/packets/telemetry'
require 'tempfile'

module Cosmos

  describe Telemetry do

    describe "initialize" do
      it "should have no warnings" do
        Telemetry.new(PacketConfig.new).warnings.should be_empty
      end
    end

    before(:each) do
      tf = Tempfile.new('unittest')
      tf.puts '# This is a comment'
      tf.puts '#'
      tf.puts 'TELEMETRY tgt1 pkt1 LITTLE_ENDIAN "TGT1 PKT1 Description"'
      tf.puts '  APPEND_ID_ITEM item1 8 UINT 1 "Item1"'
      tf.puts '    LIMITS DEFAULT 1 ENABLED 1 2 4 5'
      tf.puts '  APPEND_ITEM item2 8 UINT "Item2"'
      tf.puts '    LIMITS DEFAULT 1 ENABLED 1 2 4 5'
      tf.puts '  APPEND_ITEM item3 8 UINT "Item3"'
      tf.puts '    POLY_READ_CONVERSION 0 2'
      tf.puts '  APPEND_ITEM item4 8 UINT "Item4"'
      tf.puts '    POLY_READ_CONVERSION 0 2'
      tf.puts 'TELEMETRY tgt1 pkt2 LITTLE_ENDIAN "TGT1 PKT2 Description"'
      tf.puts '  APPEND_ID_ITEM item1 8 UINT 2 "Item1"'
      tf.puts '  APPEND_ITEM item2 8 UINT "Item2"'
      tf.puts 'TELEMETRY tgt2 pkt1 LITTLE_ENDIAN "TGT2 PKT1 Description"'
      tf.puts '  APPEND_ID_ITEM item1 8 UINT 3 "Item1"'
      tf.puts '  APPEND_ITEM item2 8 UINT "Item2"'
      tf.close

      pc = PacketConfig.new
      pc.process_file(tf.path, "SYSTEM")
      @tlm = Telemetry.new(pc)
      tf.unlink
    end

    describe "target_names" do
      it "should return an array with just UNKNOWN if no targets" do
        Telemetry.new(PacketConfig.new).target_names.should eql ["UNKNOWN"]
      end

      it "should return all target names" do
        @tlm.target_names.should eql ["TGT1","TGT2","UNKNOWN"]
      end
    end

    describe "packets" do
      it "should complain about non-existant targets" do
        expect { @tlm.packets("tgtX") }.to raise_error(RuntimeError, "Telemetry target 'TGTX' does not exist")
      end

      it "should return all packets target TGT1" do
        pkts = @tlm.packets("TGT1")
        pkts.length.should eql 2
        pkts.keys.should include("PKT1")
        pkts.keys.should include("PKT2")
      end

      it "should return all packets target TGT2" do
        pkts = @tlm.packets("TGT2")
        pkts.length.should eql 1
        pkts.keys.should include("PKT1")
      end
    end

    describe "packet" do
      it "should complain about non-existant targets" do
        expect { @tlm.packet("tgtX","pkt1") }.to raise_error(RuntimeError, "Telemetry target 'TGTX' does not exist")
      end

      it "should complain about non-existant packets" do
        expect { @tlm.packet("TGT1","PKTX") }.to raise_error(RuntimeError, "Telemetry packet 'TGT1 PKTX' does not exist")
      end

      it "should complain about the 'LATEST' packet" do
        expect { @tlm.packet("TGT1","LATEST") }.to raise_error(RuntimeError, "Telemetry packet 'TGT1 LATEST' does not exist")
      end

      it "should return the specified packet" do
        pkt = @tlm.packet("TGT1","PKT1")
        pkt.target_name.should eql "TGT1"
        pkt.packet_name.should eql "PKT1"
      end
    end

    describe "items" do
      it "should complain about non-existant targets" do
        expect { @tlm.items("tgtX","pkt1") }.to raise_error(RuntimeError, "Telemetry target 'TGTX' does not exist")
      end

      it "should complain about non-existant packets" do
        expect { @tlm.items("TGT1","PKTX") }.to raise_error(RuntimeError, "Telemetry packet 'TGT1 PKTX' does not exist")
      end

      it "should complain about the 'LATEST' packet" do
        expect { @tlm.items("TGT1","LATEST") }.to raise_error(RuntimeError, "Telemetry packet 'TGT1 LATEST' does not exist")
      end

      it "should return all items from packet TGT1/PKT1" do
        items = @tlm.items("TGT1","PKT1")
        items.length.should eql 7
        items[0].name.should eql "RECEIVED_TIMESECONDS"
        items[1].name.should eql "RECEIVED_TIMEFORMATTED"
        items[2].name.should eql "RECEIVED_COUNT"
        items[3].name.should eql "ITEM1"
        items[4].name.should eql "ITEM2"
        items[5].name.should eql "ITEM3"
        items[6].name.should eql "ITEM4"
      end
    end

    describe "item_names" do
      it "should return all the items for a given target and packet" do
        items = @tlm.item_names("TGT1","PKT1")
        expect(items).to contain_exactly('RECEIVED_TIMEFORMATTED','RECEIVED_TIMESECONDS','RECEIVED_COUNT','ITEM1','ITEM2','ITEM3','ITEM4')

        items = @tlm.item_names("TGT1","LATEST")
        expect(items).to contain_exactly('ITEM1','ITEM2','ITEM3','ITEM4')
      end
    end

    describe "packet_and_item" do
      it "should complain about non-existant targets" do
        expect { @tlm.packet_and_item("tgtX","pkt1","item1") }.to raise_error(RuntimeError, "Telemetry target 'TGTX' does not exist")
      end

      it "should complain about non-existant packets" do
        expect { @tlm.packet_and_item("TGT1","PKTX","ITEM1") }.to raise_error(RuntimeError, "Telemetry packet 'TGT1 PKTX' does not exist")
      end

      it "should complain about non-existant items" do
        expect { @tlm.packet_and_item("TGT1","PKT1","ITEMX") }.to raise_error(RuntimeError, "Packet item 'TGT1 PKT1 ITEMX' does not exist")
      end

      it "should return the packet and item" do
        pkt,item = @tlm.packet_and_item("TGT1","PKT1","ITEM1")
        item.name.should eql "ITEM1"
      end

      it "should return the LATEST packet and item if it exists" do
        pkt,item = @tlm.packet_and_item("TGT1","LATEST","ITEM1")
        pkt.packet_name.should eql "PKT2"
        item.name.should eql "ITEM1"
      end
    end

    describe "latest_packets" do
      it "should complain about non-existant targets" do
        expect { @tlm.latest_packets("tgtX","item1") }.to raise_error(RuntimeError, "Telemetry target 'TGTX' does not exist")
      end

      it "should complain about non-existant items" do
        expect { @tlm.latest_packets("TGT1","ITEMX") }.to raise_error(RuntimeError, "Telemetry item 'TGT1 LATEST ITEMX' does not exist")
      end

      it "should return the packets that contain the item" do
        pkts = @tlm.latest_packets("TGT1","ITEM1")
        pkts.length.should eql 2
        pkts[0].packet_name.should eql "PKT1"
        pkts[1].packet_name.should eql "PKT2"
      end
    end

    describe "newest_packet" do
      it "should complain about non-existant targets" do
        expect { @tlm.newest_packet("tgtX","item1") }.to raise_error(RuntimeError, "Telemetry target 'TGTX' does not exist")
      end

      it "should complain about non-existant items" do
        expect { @tlm.newest_packet("TGT1","ITEMX") }.to raise_error(RuntimeError, "Telemetry item 'TGT1 LATEST ITEMX' does not exist")
      end

      context "with two valid timestamps" do
        it "should return the latest packet (PKT1)" do
          time = Time.now
          @tlm.packet("TGT1","PKT1").received_time = time + 1
          @tlm.packet("TGT1","PKT2").received_time = time
          pkt = @tlm.newest_packet("TGT1","ITEM1")
          pkt.packet_name.should eql "PKT1"
          pkt.received_time.should eql(time + 1)
        end

        it "should return the latest packet (PKT2)" do
          time = Time.now
          @tlm.packet("TGT1","PKT1").received_time = time
          @tlm.packet("TGT1","PKT2").received_time = time + 1
          pkt = @tlm.newest_packet("TGT1","ITEM1")
          pkt.packet_name.should eql "PKT2"
          pkt.received_time.should eql(time + 1)
        end

        it "should return the last packet if timestamps are equal" do
          time = Time.now
          @tlm.packet("TGT1","PKT1").received_time = time
          @tlm.packet("TGT1","PKT2").received_time = time
          pkt = @tlm.newest_packet("TGT1","ITEM1")
          pkt.packet_name.should eql "PKT2"
          pkt.received_time.should eql(time)
        end
      end

      context "with one or more nil timestamps" do
        it "should return the last packet if neither has a timestamp" do
          pkt = @tlm.newest_packet("TGT1","ITEM1")
          pkt.packet_name.should eql "PKT2"
          pkt.received_time.should be_nil
        end

        it "should return the packet with a timestamp (PKT1)" do
          time = Time.now
          @tlm.packet("TGT1","PKT1").received_time = time
          pkt = @tlm.newest_packet("TGT1","ITEM1")
          pkt.packet_name.should eql "PKT1"
          pkt.received_time.should eql time
        end

        it "should return the packet with a timestamp (PKT2)" do
          time = Time.now
          @tlm.packet("TGT1","PKT2").received_time = time
          pkt = @tlm.newest_packet("TGT1","ITEM1")
          pkt.packet_name.should eql "PKT2"
          pkt.received_time.should eql time
        end
      end
    end

    describe "identify!" do
      it "should return nil with a nil buffer" do
        @tlm.identify!(nil).should be_nil
      end

      it "should only check the targets given" do
        buffer = "\x01\x02\x03\x04"
        @tlm.identify!(buffer,["TGT1"])
        pkt = @tlm.packet("TGT1","PKT1")
        pkt.enable_method_missing
        pkt.item1.should eql 1
        pkt.item2.should eql 2
        pkt.item3.should eql 6.0
        pkt.item4.should eql 8.0
      end

      it "should return nil with unknown targets given" do
        buffer = "\x01\x02\x03\x04"
        @tlm.identify!(buffer,["TGTX"]).should be_nil
      end

      context "with an unknown buffer" do
        it "should log an invalid sized buffer" do
          capture_io do |stdout|
            buffer = "\x01\x02\x03\x04\x05"
            @tlm.identify!(buffer)
            pkt = @tlm.packet("TGT1","PKT1")
            pkt.enable_method_missing
            pkt.item1.should eql 1
            pkt.item2.should eql 2
            pkt.item3.should eql 6.0
            pkt.item4.should eql 8.0
            stdout.string.should match(/ERROR: TGT1 PKT1 received with actual packet length of 5 but defined length of 4/)
          end
        end

        it "should identify TGT1 PKT1" do
          buffer = "\x01\x02\x03\x04"
          @tlm.identify!(buffer)
          pkt = @tlm.packet("TGT1","PKT1")
          pkt.enable_method_missing
          pkt.item1.should eql 1
          pkt.item2.should eql 2
          pkt.item3.should eql 6.0
          pkt.item4.should eql 8.0
        end

        it "should identify TGT1 PKT2" do
          buffer = "\x02\x02"
          @tlm.identify!(buffer)
          pkt = @tlm.packet("TGT1","PKT2")
          pkt.enable_method_missing
          pkt.item1.should eql 2
          pkt.item2.should eql 2
        end

        it "should identify TGT2 PKT1" do
          buffer = "\x03\x02"
          @tlm.identify!(buffer)
          pkt = @tlm.packet("TGT2","PKT1")
          pkt.enable_method_missing
          pkt.item1.should eql 3
          pkt.item2.should eql 2
        end
      end
    end

    describe "update!" do
      it "should complain about non-existant targets" do
        expect { @tlm.update!("TGTX","PKT1","\x00") }.to raise_error(RuntimeError, "Telemetry target 'TGTX' does not exist")
      end

      it "should complain about non-existant packets" do
        expect { @tlm.update!("TGT1","PKTX","\x00") }.to raise_error(RuntimeError, "Telemetry packet 'TGT1 PKTX' does not exist")
      end

      it "should complain about the 'LATEST' packet" do
        expect { @tlm.update!("TGT1","LATEST","\x00") }.to raise_error(RuntimeError, "Telemetry packet 'TGT1 LATEST' does not exist")
      end

      it "should complain with a nil buffer" do
        expect { @tlm.update!("TGT1","PKT1",nil) }.to raise_error(ArgumentError, "Buffer class is NilClass but must be String")
      end

      it "should log an invalid sized buffer" do
        capture_io do |stdout|
          buffer = "\x01\x02\x03\x04\x05"
          @tlm.update!("TGT1","PKT1",buffer)
          pkt = @tlm.packet("TGT1","PKT1")
          pkt.enable_method_missing
          pkt.item1.should eql 1
          pkt.item2.should eql 2
          pkt.item3.should eql 6.0
          pkt.item4.should eql 8.0
          stdout.string.should match(/ERROR: TGT1 PKT1 received with actual packet length of 5 but defined length of 4/)
        end
      end

      it "should update a packet with the given data" do
        @tlm.update!("TGT1","PKT1","\x01\x02\x03\x04")
        pkt = @tlm.packet("TGT1","PKT1")
        pkt.enable_method_missing
        pkt.item1.should eql 1
        pkt.item2.should eql 2
        pkt.item3.should eql 6.0
        pkt.item4.should eql 8.0
      end
    end

    describe "limits_change_callback" do
      it "should assign a callback to each packet" do
        callback = Object.new
        expect(callback).to receive(:call).twice
        @tlm.limits_change_callback = callback
        @tlm.update!("TGT1","PKT1","\x01\x02\x03\x04")
        @tlm.update!("TGT1","PKT2","\x05\x06")
        @tlm.update!("TGT2","PKT1","\x07\x08")
        @tlm.packet("TGT1","PKT1").check_limits
        @tlm.packet("TGT1","PKT2").check_limits
        @tlm.packet("TGT2","PKT1").check_limits
      end
    end

    describe "check_stale" do
      it "should check each packet for staleness" do
        @tlm.check_stale
        @tlm.packet("TGT1","PKT1").stale.should be_truthy
        @tlm.packet("TGT1","PKT2").stale.should be_truthy
        @tlm.packet("TGT2","PKT1").stale.should be_truthy

        @tlm.packet("TGT1","PKT1").check_limits
        @tlm.packet("TGT1","PKT2").check_limits
        @tlm.packet("TGT2","PKT1").check_limits
        @tlm.check_stale
        @tlm.packet("TGT1","PKT1").stale.should be_falsey
        @tlm.packet("TGT1","PKT2").stale.should be_falsey
        @tlm.packet("TGT2","PKT1").stale.should be_falsey
      end
    end

    describe "clear_counters" do
      it "should clear each packet's receive count " do
        @tlm.packet("TGT1","PKT1").received_count = 1
        @tlm.packet("TGT1","PKT2").received_count = 2
        @tlm.packet("TGT2","PKT1").received_count = 3
        @tlm.clear_counters
        @tlm.packet("TGT1","PKT1").received_count.should eql 0
        @tlm.packet("TGT1","PKT2").received_count.should eql 0
        @tlm.packet("TGT2","PKT1").received_count.should eql 0
      end
    end

    describe "value" do
      it "should complain about non-existant targets" do
        expect { @tlm.value("TGTX","PKT1","ITEM1") }.to raise_error(RuntimeError, "Telemetry target 'TGTX' does not exist")
      end

      it "should complain about non-existant packets" do
        expect { @tlm.value("TGT1","PKTX","ITEM1") }.to raise_error(RuntimeError, "Telemetry packet 'TGT1 PKTX' does not exist")
      end

      it "should complain about non-existant items" do
        expect { @tlm.value("TGT1","PKT1","ITEMX") }.to raise_error(RuntimeError, "Packet item 'TGT1 PKT1 ITEMX' does not exist")
      end

      it "should return the value" do
        @tlm.value("TGT1","PKT1","ITEM1").should eql 0
      end

      it "should return the value using LATEST" do
        @tlm.value("TGT1","LATEST","ITEM1").should eql 0
      end
    end

    describe "set_tlm" do
      it "should complain about non-existant targets" do
        expect { @tlm.set_value("TGTX","PKT1","ITEM1", 1) }.to raise_error(RuntimeError, "Telemetry target 'TGTX' does not exist")
      end

      it "should complain about non-existant packets" do
        expect { @tlm.set_value("TGT1","PKTX","ITEM1", 1) }.to raise_error(RuntimeError, "Telemetry packet 'TGT1 PKTX' does not exist")
      end

      it "should complain about non-existant items" do
        expect { @tlm.set_value("TGT1","PKT1","ITEMX", 1) }.to raise_error(RuntimeError, "Packet item 'TGT1 PKT1 ITEMX' does not exist")
      end

      it "should set the value" do
        @tlm.set_value("TGT1","PKT1","ITEM1",1)
        @tlm.value("TGT1","PKT1","ITEM1").should eql 1
      end

      it "should set the value using LATEST" do
        @tlm.set_value("TGT1","LATEST","ITEM1",1)
        @tlm.value("TGT1","PKT1","ITEM1").should eql 0
        @tlm.value("TGT1","PKT2","ITEM1").should eql 1
      end
    end

    describe "values_and_limits_states" do
      it "should complain about non-existant targets" do
        expect { @tlm.values_and_limits_states([["TGTX","PKT1","ITEM1"]]) }.to raise_error(RuntimeError, "Telemetry target 'TGTX' does not exist")
      end

      it "should complain about non-existant packets" do
        expect { @tlm.values_and_limits_states([["TGT1","PKTX","ITEM1"]]) }.to raise_error(RuntimeError, "Telemetry packet 'TGT1 PKTX' does not exist")
      end

      it "should complain about non-existant items" do
        expect { @tlm.values_and_limits_states([["TGT1","PKT1","ITEMX"]]) }.to raise_error(RuntimeError, "Packet item 'TGT1 PKT1 ITEMX' does not exist")
      end

      it "should complain about non-existant value_types" do
        expect { @tlm.values_and_limits_states([["TGT1","PKT1","ITEM1"]],:MINE) }.to raise_error(ArgumentError, "Unknown value type on read: MINE")
      end

      it "should complain if passed a single array" do
        expect { @tlm.values_and_limits_states(["TGT1","PKT1","ITEM1"]) }.to raise_error(ArgumentError, /item_array must be a nested array/)
      end

      it "should complain about the wrong number of parameters" do
        expect { @tlm.values_and_limits_states([["TGT1","PKT1","ITEM1"]],:RAW,:RAW) }.to raise_error(ArgumentError, /wrong number of arguments/)
      end

      it "should read all the specified values" do
        @tlm.update!("TGT1","PKT1","\x01\x02\x03\x04")
        @tlm.update!("TGT1","PKT2","\x05\x06")
        @tlm.update!("TGT2","PKT1","\x07\x08")
        @tlm.packet("TGT1","PKT1").check_limits
        @tlm.packet("TGT1","PKT2").check_limits
        @tlm.packet("TGT2","PKT1").check_limits
        items = []
        items << %w(TGT1 PKT1 ITEM1)
        items << %w(TGT1 PKT2 ITEM2)
        items << %w(TGT2 PKT1 ITEM1)
        vals = @tlm.values_and_limits_states(items)
        vals[0][0].should eql 1
        vals[0][1].should eql 6
        vals[0][2].should eql 7
        vals[1][0].should eql :RED_LOW
        vals[1][1].should be_nil
        vals[1][2].should be_nil
        vals[2][0].should eql [1.0, 2.0, 4.0, 5.0]
        vals[2][1].should be_nil
        vals[2][2].should be_nil
      end

      it "should read all the specified values with specified value_types" do
        @tlm.update!("TGT1","PKT1","\x01\x02\x03\x04")
        @tlm.update!("TGT1","PKT2","\x05\x06")
        @tlm.update!("TGT2","PKT1","\x07\x08")
        @tlm.packet("TGT1","PKT1").check_limits
        @tlm.packet("TGT1","PKT2").check_limits
        @tlm.packet("TGT2","PKT1").check_limits
        items = []
        items << %w(TGT1 PKT1 ITEM1)
        items << %w(TGT1 PKT1 ITEM2)
        items << %w(TGT1 PKT1 ITEM3)
        items << %w(TGT1 PKT1 ITEM4)
        items << %w(TGT1 PKT2 ITEM2)
        items << %w(TGT2 PKT1 ITEM1)
        formats = [:CONVERTED, :RAW, :CONVERTED, :RAW, :CONVERTED, :CONVERTED]
        vals = @tlm.values_and_limits_states(items,formats)
        vals[0][0].should eql 1
        vals[0][1].should eql 2
        vals[0][2].should eql 6.0
        vals[0][3].should eql 4
        vals[0][4].should eql 6
        vals[0][5].should eql 7
        vals[1][0].should eql :RED_LOW
        vals[1][1].should eql :YELLOW_LOW
        vals[1][2].should be_nil
        vals[1][3].should be_nil
        vals[1][4].should be_nil
        vals[1][5].should be_nil
        vals[2][0].should eql [1.0, 2.0, 4.0, 5.0]
        vals[2][1].should eql [1.0, 2.0, 4.0, 5.0]
        vals[2][2].should be_nil
        vals[2][3].should be_nil
        vals[2][4].should be_nil
        vals[2][5].should be_nil
      end
    end

    describe "all" do
      it "should return all packets" do
        @tlm.all.keys.should eql %w(UNKNOWN TGT1 TGT2)
      end
    end

  end
end

