#!/usr/bin/env ruby
#######################################################################
#  NAME:
#    test_simple_rrd.rb
#
#  AUTHOR:
#    Michael Utke, Jr. <mutke@shutterfly.com>
#
#  DESCRIPTION:
#    Unit tests for SimpleRRD class
#
#  Copyright (c) Shutterfly, Inc. 2010-2011. All Rights reserved.
#
#  This file is part of SimpleRRD.
#
#   SimpleRRD is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Lesser General Public License
#   version 2.1 as published by the Free Software Foundation.
#
#   SimpleRRD is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Lesser General Public License for more details.
#
#   You should have received a copy of the GNU Lesser General Public
#   License along with SimpleRRD.  If not, see
#   <http://www.gnu.org/licenses/>.
#######################################################################

require 'simple_rrd'
require 'test/unit'
require 'test_unit_extensions'

class SimpleRRDTest < Test::Unit::TestCase
    attr_reader :path, :time
    @@file = '/var/tmp/SimpleRRDs/test/dataset.rrd'
    @@time = Time.parse('00:00')
    @@example_step_values = [30, 60, 120, 300, 600]
    @@this_class = SimpleRRD

    # Setup and Teardown methods called
    def setup
        @sr = @@this_class.new
    end

    def teardown
        File.delete(@@file) if File.exists?(@@file)
    end

    must 'initialize SimpleRRD without arguments' do
        assert_not_nil(@sr)
        assert_kind_of(@@this_class, @sr)
    end

    must 'read instance variables from file on disk' do
        @sr.path = @@file
        @sr.when = @@time

        @sr.step      = 30
        @sr.kind      = :DERIVE
        @sr.min       = 60
        @sr.max       = 120
        @sr.duration  = 78840000
        @sr.xff       = 0.1
        @sr.heartbeat = 5
        @sr.create

        @sr = @@this_class.new
        assert_equal(60, @sr.step) # Default

        @sr = @@this_class.new(@@file)
        assert_equal(30, @sr.step) # ivars as set above
        assert_equal(:DERIVE, @sr.kind)
        assert_equal(60, @sr.min)
        assert_equal(120, @sr.max)
        assert_equal(78840000, @sr.duration)
        assert_equal(0.1, @sr.xff)
        assert_equal(5, @sr.heartbeat)
    end

    ### @path
    must 'nil @path by default' do
        assert_nil(@sr.path)
    end

    must 'set and get @path as empty string' do
        @sr.path = ''
        assert_kind_of(String, @sr.path)
        assert_equal('', @sr.path)
    end

    must 'set and get @path as file path' do
        @sr.path = @@file
        assert_kind_of(String, @sr.path)
        assert_equal(@@file, @sr.path)
        @sr = @@this_class.new(@@file+'.new')
        assert_equal(@@file+'.new', @sr.path)
    end

    must 'set and get @path as nil' do
        @sr.path = @@file
        assert_equal(@@file, @sr.path)
        @sr.path = nil
        assert_nil(@sr.path)
    end

    ### @when
    must '@when is Time.now by default' do
        assert_not_nil(@sr.when)
        assert_kind_of(Time, @sr.when)
        assert_equal(true, Time.now.to_i-@sr.when.to_i < 5)
    end

    must 'set and get @when as Time object' do
        @sr.when = @@time+1
        assert_kind_of(Time, @sr.when)
        assert_equal(@@time+1, @sr.when)
        @sr.when += 1
        assert_equal(@@time+2, @sr.when)
    end

    must 'initialize SimpleRRD with a specific @when value' do
        @sr = @@this_class.new(@@file, @@time)
        assert_kind_of(Time, @sr.when)
        assert_equal(@@time, @sr.when)
    end

    must 'set and get @when as Time.at(0)' do
        @sr.when = Time.at(0)
        assert_equal(0, @sr.when.to_i)
    end

    must 'set and get @when as nil' do
        @sr.when = nil
        assert_nil(@sr.when)
    end

    ### ::now
    must 'return current time for ::now' do
        assert_kind_of(Time, @@this_class.now)
        assert_equal(true, Time.now.to_i-@@this_class.now.to_i < 5)
    end
    
    ### @step
    must '@step is 60 by default' do
        assert_not_nil(@sr.step)
        assert_kind_of(Fixnum, @sr.step)
        assert_equal(60, @sr.step)
    end

    must 'set and get @step as Fixnum' do
        @sr.step = 1
        assert_kind_of(Fixnum, @sr.step)
        assert_equal(1, @sr.step)
    end

    must 'set and get @step as zero' do
        @sr.step = 0
        assert_equal(0, @sr.step)
    end

    must 'set and get @step as negative number' do
        @sr.step = -1
        assert_equal(-1, @sr.step)
    end

    must 'set and get @step as nil' do
        @sr.step = nil
        assert_nil(@sr.step)
    end

    must 'set and get @step as String' do
        @sr.step = 'foo'
        assert_equal('foo', @sr.step)
    end

    ### @kind
    must '@kind is :GAUGE by default' do
        assert_not_nil(@sr.kind)
        assert_kind_of(Symbol, @sr.kind)
        assert_equal(:GAUGE, @sr.kind)
    end

    must 'set and get @kind as Symbol' do
        @sr.kind = :COUNTER
        assert_equal(:COUNTER, @sr.kind)
        @sr.kind = :absolute
        assert_equal(:absolute, @sr.kind)
        @sr.kind = :foo
        assert_equal(:foo, @sr.kind)
    end

    must 'set and get @kind as String' do
        @sr.kind = 'COUNTER'
        assert_equal('COUNTER', @sr.kind)
        @sr.kind = 'absolute'
        assert_equal('absolute', @sr.kind)
        @sr.kind = 'foo'
        assert_equal('foo', @sr.kind)
    end

    must 'set and get @kind as nil' do
        @sr.kind = nil
        assert_nil(@sr.kind)
    end

    must 'set and get @kind as Fixnum' do
        @sr.kind = 8
        assert_equal(8, @sr.kind)
    end

    ### @@SUPPORTED_KINDS
    must 'support :GAUGE DST' do
        assert_equal(true, @@this_class.SUPPORTED_KINDS.include?(:GAUGE))
    end

    must 'support :COUNTER DST' do
        assert_equal(true, @@this_class.SUPPORTED_KINDS.include?(:COUNTER))
    end
    
    must 'support :DERIVE DST' do
        assert_equal(true, @@this_class.SUPPORTED_KINDS.include?(:DERIVE))
    end

    must 'support :ABSOLUTE DST' do
        assert_equal(true, @@this_class.SUPPORTED_KINDS.include?(:ABSOLUTE))
    end
    
    ### @values
    must '@values is [] by default' do
        assert_not_nil(@sr.values)
        assert_kind_of(Array, @sr.values)
        assert_equal(0, @sr.values.length)
    end

    must '@values cannot be set' do
        assert_raise NoMethodError do
            @sr.values = [1,2,3]
        end
    end

    ### @min
    must '@min is U by default' do
        assert_not_nil(@sr.min)
        assert_kind_of(String, @sr.min)
        assert_equal('U', @sr.min)
    end

    must 'set and get @min as Fixnum' do
        @sr.min = 1
        assert_kind_of(Fixnum, @sr.min)
        assert_equal(1, @sr.min)
    end

    must 'set and get @min as zero' do
        @sr.min = 0
        assert_equal(0, @sr.min)
    end

    must 'set and get @min as negative number' do
        @sr.min = -1
        assert_equal(-1, @sr.min)
    end

    must 'set and get @min as nil' do
        @sr.min = nil
        assert_nil(@sr.min)
    end

    must 'set and get @min as String' do
        @sr.min = 'foo'
        assert_equal('foo', @sr.min)
        @sr.min = 'U'
        assert_equal('U', @sr.min)
    end

    ### @max
    must '@max is U by default' do
        assert_not_nil(@sr.max)
        assert_kind_of(String, @sr.max)
        assert_equal('U', @sr.max)
    end

    must 'set and get @max as Fixnum' do
        @sr.max = 1
        assert_kind_of(Fixnum, @sr.max)
        assert_equal(1, @sr.max)
    end

    must 'set and get @max as zero' do
        @sr.max = 0
        assert_equal(0, @sr.max)
    end

    must 'set and get @max as negative number' do
        @sr.max = -1
        assert_equal(-1, @sr.max)
    end

    must 'set and get @max as nil' do
        @sr.max = nil
        assert_nil(@sr.max)
    end

    must 'set and get @max as String' do
        @sr.max = 'foo'
        assert_equal('foo', @sr.max)
        @sr.max = 'U'
        assert_equal('U', @sr.max)
    end

    ### @duration
    must '@duration is 5 years (as seconds) by default' do
        assert_equal(60 * 60 * 24 * 365 * 5, @sr.duration)
    end

    must 'set and get @duration as Fixnum' do
        @sr.duration = 60 * 60 * 24 * 365 * 5
        assert_equal(60 * 60 * 24 * 365 * 5, @sr.duration)
    end

    must 'set and get @duration as nil' do
        @sr.duration = nil
        assert_nil(@sr.duration)
    end

    must 'set and get @duration as String' do
        @sr.duration = 'Ten Years'
        assert_equal('Ten Years', @sr.duration)
    end

    ### @xff
    must '@xff is 0.5 by default' do
        assert_equal(0.5, @sr.xff)
    end

    must 'set and get @xff as positive Float < 1' do
        @sr.xff = 0.9
        assert_equal(0.9, @sr.xff)
    end

    must 'set and get @xff as nil' do
        @sr.xff = nil
        assert_nil(@sr.xff)
    end

    must 'set and get @xff as Fixnum' do
        @sr.xff = 1
        assert_equal(1, @sr.xff)
    end

    must 'set and get @xff as String' do
        @sr.xff = 'Zero Point Zero Two'
        assert_equal('Zero Point Zero Two', @sr.xff)
    end

    must 'set and get @xff as Zero' do
        @sr.xff = 0
        assert_equal(0, @sr.xff)
    end

    must 'set and get @xff as a negative Float' do
        @sr.xff = -0.01
        assert_equal(-0.01, @sr.xff)
    end

    ### @heartbeat
    must '@heartbeat is 6 by default' do
        assert_equal(6, @sr.heartbeat)
    end

    must 'set and get @heartbeat as positive Fixnum' do
        @sr.heartbeat = 14
        assert_equal(14, @sr.heartbeat)
    end

    must 'set and get @heartbeat as nil' do
        @sr.heartbeat = nil
        assert_nil(@sr.heartbeat)
    end

    must 'set and get @heartbeat as String' do
        @sr.heartbeat = 'Seven'
        assert_equal('Seven', @sr.heartbeat)
    end

    must 'set and get @heartbeat as Zero' do
        @sr.heartbeat = 0
        assert_equal(0, @sr.heartbeat)
    end

    must 'set and get @heartbeat as a negative Fixnum' do
        @sr.heartbeat = -18
        assert_equal(-18, @sr.heartbeat)
    end

    ### @@DS_NAME
    must '@@DS_NAME is "data_source" by default' do
        assert_equal('data_source', @@this_class.DS_NAME)
    end

    ### ::DS_NAME
    must 'return @@DS_NAME for ::DS_NAME' do
        assert_equal(@@this_class.DS_NAME, @@this_class.send(:DS_NAME))
    end

    ### #path=
    must 'read instance variables from file on disk when setting @path' do
        @sr.path = @@file
        @sr.when = @@time

        @sr.step      = 30
        @sr.kind      = :DERIVE
        @sr.min       = 60
        @sr.max       = 120
        @sr.duration  = 78840000
        @sr.xff       = 0.1
        @sr.heartbeat = 5
        @sr.create

        @sr = @@this_class.new
        assert_equal(60, @sr.step) # Default

        @sr.path = @@file
        assert_equal(30, @sr.step) # ivars as set above
        assert_equal(:DERIVE, @sr.kind)
        assert_equal(60, @sr.min)
        assert_equal(120, @sr.max)
        assert_equal(78840000, @sr.duration)
        assert_equal(0.1, @sr.xff)
        assert_equal(5, @sr.heartbeat)
    end

    ### #valid?
    must 'SimpleRRD responds to #valid?' do
        assert_respond_to(@sr, 'valid?')
    end

    must 'SimpleRRD defaults are !#valid?' do
        assert_equal(false, @sr.valid?)
    end

    # @path
    must 'determine nil @path is !#valid?' do
        assert_nil(@sr.path)
        assert_equal(false, @sr.valid?)
    end

    must 'determine empty String @path is !#valid?' do
        @sr.path = ''
        assert_equal(false, @sr.valid?)
    end

    must 'determine non-empty String @path is !#valid?' do
        @sr.path = @@file
        assert_equal(true, @sr.valid?)
    end

    # @when
    must 'determine nil @when is !#valid?' do
        @sr.path = @@file
        @sr.when = nil
        assert_equal(false, @sr.valid?)
    end

    must 'determine String @when is !#valid?' do
        @sr.path = @@file
        @sr.when = 'foo'
        assert_equal(false, @sr.valid?)
    end

    must 'determine Fixnum @when is !#valid?' do
        @sr.path = @@file
        @sr.when = 1234567
        assert_equal(false, @sr.valid?)
    end

    must 'determine Time.at(0) @when is #valid?' do
        @sr.path = @@file
        @sr.when = Time.at(0)
        assert_equal(true, @sr.valid?)
    end

    must 'determine Time.parse("12:00") @when is #valid?' do
        @sr.path = @@file
        @sr.when = Time.parse("12:00")
        assert_equal(true, @sr.valid?)
    end

    # @step
    must 'determine positive Fixnum @step is #valid?' do
        @sr.path = @@file
        assert_equal(true, @sr.valid?)
        @sr.step = 30
        assert_equal(true, @sr.valid?)
    end

    must 'determine nil @step is !#valid?' do
        @sr.path = @@file
        @sr.step = nil
        assert_equal(false, @sr.valid?)
    end

    must 'determine zero @step is !#valid?' do
        @sr.path = @@file
        @sr.step = 0
        assert_equal(false, @sr.valid?)
    end

    must 'determine negative @step is !#valid?' do
        @sr.path = @@file
        @sr.step = -1
        assert_equal(false, @sr.valid?)
    end

    must 'determine String @step is !#valid?' do
        @sr.path = @@file
        @sr.step = 'foo'
        assert_equal(false, @sr.valid?)
    end

    # @kind
    must 'determine known @kind is #valid?' do
        @sr.path = @@file
        @@this_class.SUPPORTED_KINDS.each do |kind|
            @sr.kind = kind
            assert_equal(true, @sr.valid?)
        end
    end

    must 'determine unknown @kind is !#valid?' do
        @sr.path = @@file
        @sr.kind = :foo
        assert_equal(false, @sr.valid?)
        @sr.kind = 8
        assert_equal(false, @sr.valid?)
    end

    must 'determine nil @kind is !#valid? (nil)' do
        @sr.path = @@file
        @sr.kind = nil
        assert_equal(false, !!@sr.valid?)
        assert_nil(@sr.valid?)
    end

    must 'determine known @kind as String is #valid?' do
        @sr.path = @@file
        @@this_class.SUPPORTED_KINDS.each do |kind|
            @sr.kind = kind.to_s
            assert_equal(true, @sr.valid?)
        end
    end

    must 'determine known @kind of any case is #valid?' do
        @sr.path = @@file
        @@this_class.SUPPORTED_KINDS.each do |kind|
            @sr.kind = kind.to_s
            assert_equal(true, @sr.valid?)
            @sr.kind = kind.to_s.downcase
            assert_equal(true, @sr.valid?)
            @sr.kind = kind.to_s.capitalize
            assert_equal(true, @sr.valid?)
        end
    end

    # @min
    must 'determine positive Fixnum @min is #valid?' do
        @sr.path = @@file
        assert_equal(true, @sr.valid?)
        @sr.min = 10
        assert_equal(true, @sr.valid?)
    end

    must 'determine nil @min is !#valid?' do
        @sr.path = @@file
        @sr.min = nil
        assert_equal(false, @sr.valid?)
    end

    must 'determine zero @min is #valid?' do
        @sr.path = @@file
        @sr.min = 0
        assert_equal(true, @sr.valid?)
    end

    must 'determine negative @min is #valid?' do
        @sr.path = @@file
        @sr.min = -1
        assert_equal(true, @sr.valid?)
    end

    must 'determine String @min = U is #valid?' do
        @sr.path = @@file
        @sr.min = 'U'
        assert_equal(true, @sr.valid?)
    end

    must 'determine non-U String @min is !#valid?' do
        @sr.path = @@file
        @sr.min = 'Ten Years'
        assert_equal(false, @sr.valid?)
    end

    # @max
    must 'determine positive Fixnum @max is #valid?' do
        @sr.path = @@file
        assert_equal(true, @sr.valid?)
        @sr.max = 10
        assert_equal(true, @sr.valid?)
    end

    must 'determine nil @max is !#valid?' do
        @sr.path = @@file
        @sr.max = nil
        assert_equal(false, @sr.valid?)
    end

    must 'determine zero @max is #valid?' do
        @sr.path = @@file
        @sr.max = 0
        assert_equal(true, @sr.valid?)
    end

    must 'determine negative @max is #valid?' do
        @sr.path = @@file
        @sr.max = -1
        assert_equal(true, @sr.valid?)
    end

    must 'determine String @max = U is #valid?' do
        @sr.path = @@file
        @sr.max = 'U'
        assert_equal(true, @sr.valid?)
    end

    must 'determine non-U String @max is !#valid?' do
        @sr.path = @@file
        @sr.max = 'Ten Years'
        assert_equal(false, @sr.valid?)
    end

    must 'determine @min > @max is !#valid?' do
        @sr.path = @@file
        @sr.min = 100
        @sr.max = 1
        assert_equal(false, @sr.valid?)
    end

    # @duration
    must 'determine positive Fixnum @duration is #valid?' do
        @sr.path = @@file
        assert_equal(true, @sr.valid?)
        @sr.duration = 60 * 60 * 24 * 365 * 5
        assert_equal(true, @sr.valid?)
    end

    must 'determine nil @duration is !#valid?' do
        @sr.path = @@file
        @sr.duration = nil
        assert_equal(false, @sr.valid?)
    end

    must 'determine zero @duration is !#valid?' do
        @sr.path = @@file
        @sr.duration = 0
        assert_equal(false, @sr.valid?)
    end

    must 'determine negative @duration is !#valid?' do
        @sr.path = @@file
        @sr.duration = -1
        assert_equal(false, @sr.valid?)
    end

    must 'determine String @duration is !#valid?' do
        @sr.path = @@file
        @sr.duration = 'Ten Years'
        assert_equal(false, @sr.valid?)
    end

    # @xff
    must 'determine positive Float < 1 @xff is #valid?' do
        @sr.path = @@file
        assert_equal(true, @sr.valid?)
        @sr.xff = 0.9
        assert_equal(true, @sr.valid?)
    end

    must 'determine nil @xff is !#valid?' do
        @sr.path = @@file
        @sr.xff = nil
        assert_equal(false, @sr.valid?)
    end

    must 'determine zero @xff is !#valid?' do
        @sr.path = @@file
        @sr.xff = 0
        assert_equal(false, @sr.valid?)
    end

    must 'determine negative Float @xff is !#valid?' do
        @sr.path = @@file
        @sr.xff = -0.01
        assert_equal(false, @sr.valid?)
    end

    must 'determine Fixnum >= 1 @xff is !#valid?' do
        @sr.path = @@file
        @sr.xff = 1
        assert_equal(false, @sr.valid?)
    end

    must 'determine String @xff is !#valid?' do
        @sr.path = @@file
        @sr.xff = 'Zero Point Zero Two'
        assert_equal(false, @sr.valid?)
    end

    # @heartbeat
    must 'determine positive Fixnum @heartbeat is #valid?' do
        @sr.path = @@file
        assert_equal(true, @sr.valid?)
        @sr.heartbeat = 14
        assert_equal(true, @sr.valid?)
    end

    must 'determine nil @heartbeat is !#valid?' do
        @sr.path = @@file
        @sr.heartbeat = nil
        assert_equal(false, @sr.valid?)
    end

    must 'determine zero @heartbeat is !#valid?' do
        @sr.path = @@file
        @sr.heartbeat = 0
        assert_equal(false, @sr.valid?)
    end

    must 'determine negative Fixnum @heartbeat is !#valid?' do
        @sr.path = @@file
        @sr.heartbeat = -18
        assert_equal(false, @sr.valid?)
    end

    must 'determine String @heartbeat is !#valid?' do
        @sr.path = @@file
        @sr.heartbeat = 'Seven'
        assert_equal(false, @sr.valid?)
    end

    ### #create
    must 'respond to #create' do
        assert_respond_to(@sr, 'create')
    end

    must 'not #create file with nil path (SimpleRRD defaults)' do
        assert_nil(@sr.create)
    end

    must 'generates a file on disk on #create' do
        @sr.path = @@file
        assert_equal(true, @sr.create)
        assert_equal(true, File.exists?(@@file))
    end

    must 'generate file with readable RRD.info on #create' do
        @sr.path = @@file
        @sr.create
        assert_kind_of(Hash, RRD.info(@@file))
    end

    must 'validate each kind of RRD file on #create' do
        @sr.path = @@file
        @@this_class.SUPPORTED_KINDS.each do |kind|
            @sr.kind = kind
            @sr.create
            assert_equal(true, File.exists?(@@file))
            info = RRD.info(@@file)
            assert_equal(kind, info["ds[#{@@this_class.DS_NAME}].type"].to_sym)
            File.delete(@@file)
        end
    end

    must 'set last_update to when-step on #create' do
        @sr.path = @@file
        @sr.create
        info = RRD.info(@@file)
        assert_equal(@sr.when.to_i-@sr.step, info['last_update'])
    end

    must 'set minimal_heartbeat to @heartbeat*@step on #create' do
        @sr.path = @@file
        @sr.create
        info = RRD.info(@@file)
        assert_equal(
            @sr.heartbeat*@sr.step,
            info["ds[#{@@this_class.DS_NAME}].minimal_heartbeat"]
        )
    end

    # #create + @step & @duration
    must 'configure first RRA (LAST) on #create' do
        @sr.path = @@file
        @sr.create
        info = RRD.info(@@file)
        assert_equal("LAST", info['rra[0].cf'])
        assert_equal(1, info['rra[0].pdp_per_row'])
        assert_equal(@sr.duration/@sr.step, info['rra[0].rows'])
    end

    must 'configure second RRA (AVERAGE) on #create' do
        @sr.path = @@file
        @sr.create
        info = RRD.info(@@file)
        assert_equal("AVERAGE", info['rra[1].cf'])
        assert_equal((60*60*24)/@sr.step, info['rra[1].pdp_per_row'])
        assert_equal(@sr.duration/(60*60*24), info['rra[1].rows'])
    end

    must 'configure third RRA (MIN) on #create' do
        @sr.path = @@file
        @sr.create
        info = RRD.info(@@file)
        assert_equal("MIN", info['rra[2].cf'])
        assert_equal((60*60*24)/@sr.step, info['rra[1].pdp_per_row'])
        assert_equal(@sr.duration/(60*60*24), info['rra[1].rows'])
    end

    must 'configure fourth RRA (MAX) on #create' do
        @sr.path = @@file
        @sr.create
        info = RRD.info(@@file)
        assert_equal("MAX", info['rra[3].cf'])
        assert_equal((60*60*24)/@sr.step, info['rra[1].pdp_per_row'])
        assert_equal(@sr.duration/(60*60*24), info['rra[1].rows'])
    end

    must 'fail on #create when file already exists' do
        @sr.path = @@file
        @sr.create
        assert_equal(false, @sr.create)
    end

    must 'set @when correctly as last_update in file on #create' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.create
        info = RRD.info(@@file)
        assert_equal(@@time.to_i-@sr.step, info['last_update'])
    end

    must 'not #create file when !valid?' do
        @sr.path = @@file
        assert_equal(true, @sr.valid?)
        @sr.duration = -1
        assert_equal(false, @sr.valid?)
        assert_equal(false, @sr.create)
    end

    ### #read
    must 'respond to #read' do
        assert_respond_to(@sr, 'read')
    end

    must 'not #read a nil path (SimpleRRD defaults)' do
        assert_nil(@sr.read)
    end

    # #read + :GAUGE @kind
    must '#read the same values provided to #update for a :GAUGE file' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.create
        update_values = [1,2,3,4,5,6,7,8,9,10]
        assert_equal(true, @sr.update(update_values))
        read_values = @sr.read(@sr.step*update_values.length)
        assert_equal(update_values, read_values)
    end

    must '#read nil values provided to #update for a :GAUGE file' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.create
        update_values = [1,nil,2,nil,3]
        assert_equal(true, @sr.update(update_values))
        read_values = @sr.read(@sr.step*update_values.length)
        assert_equal(update_values, read_values)
    end

    # #read + :COUNTER and :DERIVE @kind
    must '#read the positive deltas between values for :COUNTER and :DERIVE' do
        @sr.path = @@file
        @sr.when = @@time
        [:COUNTER, :DERIVE].each do |kind|
            @sr.kind = kind
            (0..5).each do |n|
                @sr.create
                update_values = [1*n,2*n,3*n,4*n,5*n,6*n,7*n,8*n,9*n,10*n]
                assert_equal(true, @sr.update(update_values))
                assert_equal([nil], @sr.read(@sr.step)) # 1st value: no delta
                @sr.when += @sr.step
                read_values = @sr.read(@sr.step*(update_values.length-1))
                assert_equal([n]*(update_values.length-1), read_values)
                @sr.delete
            end
        end
    end

    # #read + @values
    must 'store a copy of the @values #read from RRD' do
        @sr.path = @@file
        @sr.when = @@time
        update_values = [1,2,3,4,5,6,7,8,9,10]
        @@this_class.SUPPORTED_KINDS.each do |kind|
            @sr.kind = kind
            @sr.create
            @sr.update(update_values)
            read_values = @sr.read(@sr.step*update_values.length)
            assert_equal(@sr.values, read_values)
            @sr.delete
        end
    end

    # #read + @step manipulation
    must '#read the values stored using a non-default @step' do
        @sr.path = @@file
        @@example_step_values.each do |step|
            @sr.step = step
            @sr.when = @@time
            @sr.create
            update_values = [1,2,3,4,5,6,7,8,9,10]
            @sr.update(update_values)
            @sr.step = step
            read_values = @sr.read(step*update_values.length)
            assert_equal(update_values, read_values)
            @sr.delete
        end
    end

    must '#read doubled values when @step is halved' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.create
        @sr.step = 60
        update_values = [1,2,3,4,5,6,7,8,9,10]
        @sr.update(update_values)
        @sr.step = @sr.step / 2
        read_values = @sr.read(@sr.step*update_values.length)
        assert_equal([1,1,2,2,3,3,4,4,5,5], read_values)
    end

    must '#read quadrupled values when @step is quartered' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.create
        @sr.step = 60
        update_values = [1,2,3,4,5,6,7,8,9,10]
        @sr.update(update_values)
        @sr.step = @sr.step / 4
        read_values = @sr.read(@sr.step*update_values.length)
        assert_equal(8, read_values.length) # Only 2 full minutes in 150s
        assert_equal([1,1,1,1,2,2,2,2], read_values)
    end

    # #read + rollovers
    must '#read correctly at bit boundaries for :COUNTER and :DERIVE @kind' do
        @sr.path = @@file
        @sr.when = @@time
        [:COUNTER, :DERIVE].each do |kind|
            @sr.kind = kind
            [32,64].each do |exp|
                (0..5).each do |n|
                    @sr.create
                    num = (2**(exp-2))*4-1 # Avoid overflowing Integer
                    update_values = [num-n*2,num-n,num,num+n,num+n*2,nil,n,n*2]
                    @sr.update(update_values)
                    @sr.when += @sr.step
                    read_values = @sr.read(@sr.step*(update_values.length-1))
                    assert_equal([n,n,n,n,nil,nil,n], read_values)
                    @sr.delete
                end
            end
        end
    end

    must '#read a graceful rollover for a :DERIVE file w/@min=0' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.kind = :DERIVE
        @sr.min = 0
        @sr.create
        update_values = [1,2,3,4,5,1,2,3,4,5]
        @sr.update(update_values)
        @sr.when += @sr.step
        read_values = @sr.read(@sr.step*(update_values.length-1))
        assert_equal([1,1,1,1,nil,1,1,1,1], read_values)
    end

    # #read + @min
    must 'enforce @min values for :GAUGE and :ABSOLUTE @kind' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.min = 3
        [:GAUGE, :ABSOLUTE].each do |kind|
            @sr.kind = kind
            @sr.create
            update_values = [1,2,3,4,5,1,2,3,4,5]
            @sr.update(update_values)
            read_values = @sr.read(@sr.step*(update_values.length))
            assert_equal([nil,nil,3,4,5,nil,nil,3,4,5], read_values)
            @sr.delete
        end
    end

    must 'enforce @min values for :COUNTER and :DERIVE @kind' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.min = 3
        [:COUNTER, :DERIVE].each do |kind|
            @sr.kind = kind
            @sr.create
            update_values = [0,2,4,8,16,32,32,33,34,44]
            @sr.update(update_values)
            @sr.when += @sr.step
            read_values = @sr.read(@sr.step*(update_values.length-1))
            assert_equal([nil,nil,4,8,16,nil,nil,nil,10], read_values)
            @sr.delete
        end
    end

    # #read + @max
    must 'enforce @max values for :GAUGE and :ABSOLUTE @kind' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.max = 3
        [:GAUGE, :ABSOLUTE].each do |kind|
            @sr.kind = kind
            @sr.create
            update_values = [1,2,3,4,5,1,2,3,4,5]
            @sr.update(update_values)
            read_values = @sr.read(@sr.step*(update_values.length))
            assert_equal([1,2,3,nil,nil,1,2,3,nil,nil], read_values)
            @sr.delete
        end
    end

    must 'enforce @max values for :COUNTER and :DERIVE @kind' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.max = 3
        [:COUNTER, :DERIVE].each do |kind|
            @sr.kind = kind
            @sr.create
            update_values = [0,2,4,8,16,32,32,33,34,44]
            @sr.update(update_values)
            @sr.when += @sr.step
            read_values = @sr.read(@sr.step*(update_values.length-1))
            assert_equal([2,2,nil,nil,nil,0,1,1,nil], read_values)
            @sr.delete
        end
    end

    # #read + @xff
    must '#read a sparsely populated LAST RRA with any @xff' do
        @sr.path = @@file
        @sr.when = @@time
        update_values = []
        (1..100).each do |n|
            update_values += (1..n).to_a
            update_values += [nil]*n
        end
        [0.99,0.5,0.01].each do |xff|
            @sr.xff = xff
            @sr.create
            @sr.update(update_values)
            read_values = @sr.read(@sr.step*(update_values.length))
            assert_equal(update_values, read_values)
            @sr.delete
        end
    end

    ### #update
    must 'respond to #update' do
        assert_respond_to(@sr, 'update')
    end

    must 'not update a nil @path (SimpleRRD defaults)' do
        assert_nil(@sr.update([1]))
    end

    must 'not #update any file that does not exist' do
        @sr.path = @@file
        assert_nil(@sr.update([1]))
    end

    must 'be able to fetch values stored with #update' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.create
        update_values = [1,2,3,4,5,6,7,8,9,10]
        assert_equal(true, @sr.update(update_values))
        # rrdtool fetch and RRD.fetch disagree on fstart!
        (fstart, fend, dsname, data, step) = RRD.fetch(@sr.path, "LAST",
            "--resolution", @sr.step,
            "--start", (@sr.when-@sr.step).to_i.to_s,
            "--end", (@sr.when+@sr.step*(update_values.length-1)).to_i.to_s)
        data.flatten!
        assert_equal(update_values[0], data[0])
        assert_equal(update_values[1], data[1])
        assert_equal(update_values[2], data[2])
        assert_equal(update_values[3], data[3])
        assert_equal(update_values[4], data[4])
        assert_equal(update_values[5], data[5])
        assert_equal(update_values[6], data[6])
        assert_equal(update_values[7], data[7])
        assert_equal(update_values[8], data[8])
        assert_equal(update_values[9], data[9])
    end

    must 'be able to append values with multiple #update calls' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.create
        assert_equal(true, @sr.update([1]))
        @sr.when += @sr.step
        assert_equal(true, @sr.update([2]))
        @sr.when += @sr.step
        assert_equal(true, @sr.update([3]))

        @sr.when = @@time
        # rrdtool fetch and RRD.fetch disagree on fstart!
        (fstart, fend, dsname, data, step) = RRD.fetch(@sr.path, "LAST",
            "--resolution", @sr.step,
            "--start", (@sr.when-@sr.step).to_i.to_s,
            "--end", (@sr.when+@sr.step*3).to_i.to_s)
        data.flatten!
        assert_equal(1, data[0])
        assert_equal(2, data[1])
        assert_equal(3, data[2])
    end

    must 'retrieve a single value stored via #update' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.create
        @sr.update([9])
        # rrdtool fetch and RRD.fetch disagree on fstart!
        (fstart, fend, dsname, data, step) = RRD.fetch(@sr.path, "LAST",
            "--resolution", @sr.step,
            "--start", (@sr.when-@sr.step).to_i.to_s,
            "--end", (@sr.when+@sr.step).to_i.to_s)
        data.flatten!
        assert_equal(9, data[0])
        assert_equal(true, data[1].nan?)
    end

    must 'retrieve NaN for values stored as nil in #update' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.create
        update_values = [1,nil,2,nil,3]
        @sr.update(update_values)
        # rrdtool fetch and RRD.fetch disagree on fstart!
        (fstart, fend, dsname, data, step) = RRD.fetch(@sr.path, "LAST",
            "--resolution", @sr.step,
            "--start", (@sr.when-@sr.step).to_i.to_s,
            "--end", (@sr.when+@sr.step*(update_values.length-1)).to_i.to_s)
        data.flatten!
        assert_equal(update_values[0], data[0])
        assert_equal(true, data[1].nan?)
        assert_equal(update_values[2], data[2])
        assert_equal(true, data[3].nan?)
        assert_equal(update_values[4], data[4])
    end

    must 'not #update two values to the same @when' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.create
        assert_equal(true, @sr.update([1]))
        assert_equal(false, @sr.update([1]))
        @sr.when -= @sr.step
        assert_equal(false, @sr.update([1]))
    end

    ### #delete
    must 'respond to #delete' do
        assert_respond_to(@sr, 'delete')
    end

    must 'not #delete a nil path (SimpleRRD defaults)' do
        assert_nil(@sr.delete)
    end

    must 'remove a file on disk on #delete' do
        @sr.path = @@file
        @sr.create
        assert_equal(true, File.exists?(@@file))
        assert_equal(true, @sr.delete)
        assert_equal(false, File.exists?(@@file))
    end

    must 'not allow #delete of non-existent file' do
        @sr.path = @@file
        assert_equal(nil, @sr.delete)
        @sr.create
        assert_equal(true, File.exists?(@@file))
        assert_equal(true, @sr.delete)
        assert_equal(false, File.exists?(@@file))
        assert_equal(nil, @sr.delete)
    end

    ### #last_update_time
    must 'respond to #last_update_time' do
        assert_respond_to(@sr, 'last_update_time')
    end

    must 'no #last_update_time in a nil @path (SimpleRRD defaults)' do
        assert_nil(@sr.last_update_time)
    end

    must 'no #last_update_time in an empty @path' do
        @sr.path = ''
        assert_nil(@sr.last_update_time)
    end

    must 'no #last_update_time when no file present' do
        @sr.path = @@file
        assert_nil(@sr.last_update_time)
    end

    must 'no #last_update_time when invalid file format' do
        @sr.path = @@file
        FileUtils.touch(@sr.path)
        assert_nil(@sr.last_update_time)
    end

    must 'return @when-@step for #last_update_time before first #update' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.create
        assert_equal(@sr.when-@sr.step, @sr.last_update_time)
    end

    must 'return @when for #last_update_time after 1-value update' do
        @sr.path = @@file
        @sr.when = @@time
        @sr.create
        @sr.update([1])
        assert_equal(@sr.when, @sr.last_update_time)
    end

    must 'return correct last update time for #last_update_time' do
        @sr.path = @@file
        @sr.when = @@time
        @@example_step_values.each do |count|
            @sr.create
            @sr.update([1]*count)
            assert_equal(@sr.when+@sr.step*(count-1), @sr.last_update_time)
            @sr.delete
        end
    end

    ### #exists?
    must 'respond to #exists?' do
        assert_respond_to(@sr, 'exists?')
    end

    must 'nothing #exists? in a nil @path (SimpleRRD defaults)' do
        assert_nil(@sr.exists?)
    end

    must 'nothing #exists? in an empty @path' do
        @sr.path = ''
        assert_nil(@sr.exists?)
    end

    must 'return false when no file #exists?' do
        @sr.path = @@file
        assert_equal(false, @sr.exists?)
    end

    must 'return true when file #exists?' do
        @sr.path = @@file
        @sr.create
        assert_equal(true, @sr.exists?)
    end

    ### #readable?
    must 'respond to #readable?' do
        assert_respond_to(@sr, 'readable?')
    end

    must 'nothing #readable? in a nil @path (SimpleRRD defaults)' do
        assert_nil(@sr.readable?)
    end

    must 'nothing #readable? in an empty @path' do
        @sr.path = ''
        assert_nil(@sr.readable?)
    end

    must 'nothing #readable? when no file present' do
        @sr.path = @@file
        assert_nil(@sr.readable?)
    end

    must 'return true when file #readable?' do
        @sr.path = @@file
        @sr.create
        assert_equal(true, @sr.readable?)
    end

    must 'return false when file !#readable? due to permissions' do
        @sr.path = @@file
        @sr.create
        File.chmod(0200, @sr.path)
        assert_equal(false, @sr.readable?)
    end

    must 'return true when file !#readable? due wrong format' do
        @sr.path = @@file
        FileUtils.touch(@sr.path)
        assert_equal(false, @sr.readable?)
    end

    ### #writable?
    must 'respond to #writable?' do
        assert_respond_to(@sr, 'writable?')
    end

    must 'nothing #writable? in a nil @path (SimpleRRD defaults)' do
        assert_nil(@sr.writable?)
    end

    must 'nothing #writable? in an empty @path' do
        @sr.path = ''
        assert_nil(@sr.writable?)
    end

    must 'nothing #writable? when no file present' do
        @sr.path = @@file
        assert_nil(@sr.writable?)
    end

    must 'return true when file #writable?' do
        @sr.path = @@file
        @sr.create
        assert_equal(true, @sr.writable?)
    end

    must 'return false when file !#writable? due to permissions' do
        @sr.path = @@file
        @sr.create
        File.chmod(0400, @sr.path)
        assert_equal(false, @sr.writable?)
        File.chmod(0600, @sr.path)
        assert_equal(true, @sr.writable?)
    end

    must 'return true when file !#writable? due wrong format' do
        @sr.path = @@file
        FileUtils.touch(@sr.path)
        assert_equal(false, @sr.writable?)
    end

    ### #ds_name
    must 'return @@DS_NAME for #ds_name' do
        @sr.path = @@file
        @sr.create
        assert_equal(@@this_class.DS_NAME, @sr.send(:ds_name))
    end

end