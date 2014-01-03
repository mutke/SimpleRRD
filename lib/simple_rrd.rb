#!/usr/bin/env ruby
# = simple_rrd.rb
# This file contains the SimpleRRD class definition

require 'fileutils'
require 'time'
require 'RRD'

#
# Simplified Create, Read, Update, Delete wrapper for ruby's RRDtool
# bindings.  Requires only _path_ parameter, then uses sensible defaults
# for all other parameters (while enabling tweaking).
#
# == Example
#    require 'simple_rrd'
#    sr = SimpleRRD.new('/var/tmp/test.rrd') # timestamp default = now
#    sr.when = Time.parse('00:00')           # timestamp set to midnight
#    sr.create                               # Returns true when created
#    sr.update([2,4,6,8,10])                 # Add 5 mins of values
#    arr = sr.read(180)                      # Returns [2.0,4.0,6.0]
#
# == Contact
#
# Author::  Michael Utke, Jr. (mailto:mutke@shutterfly.com)
# Website:: http://www.shutterfly.com
# Date::    Friday Jan 3, 2014
# Copyright:: (c) Shutterfly, Inc. 2010-2014. All Rights reserved.
# License::
#   This file is part of SimpleRRD.
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
#
class SimpleRRD

    # Path to the underlying RRD file.
    attr_accessor :path

    # Timestamp to use for #create, #update, and #read methods.
    attr_accessor :when

    # Class method for calculating 'now'.  
    # Override in child classes with different needs (e.g. minute alignment)
    #
    # @return [Time] current time.
    def self.now
        Time.now
    end

    # Number of seconds between values for #create, #read, and #update.
    # Defaults to 60 (1 minute)
    attr_accessor :step

    # Data Source Type (DST) to use in the RRD.
    # Defaults to :GAUGE
    attr_accessor :kind

    # Data Source Type (DST) supported by this class
    @@SUPPORTED_KINDS = [:GAUGE, :COUNTER, :DERIVE, :ABSOLUTE]

    # Class accessor for @@SUPPORTED_KINDS
    #
    # @return [Array] List of supported @kind values
    def self.SUPPORTED_KINDS
        @@SUPPORTED_KINDS
    end

    # Last values #read from RRD file.
    attr_reader :values

    # Min value allowed (rollover protection for :DERIVE and :COUNTER DSTs.)
    # Defaults to U (unknown, i.e. none)
    attr_accessor :min

    # Max value allowed (rollover protection for :DERIVE and :COUNTER DSTs.)
    # Defaults to U (unknown, i.e. none)
    attr_accessor :max

    # Seconds worth of of datapoints to store in RRD file.
    # Defaults to 157680000 (5 years as seconds)
    attr_accessor :duration

    # rrdtool's xfiles factor.  Irrelevant for primary (LAST) RRA.
    # Defaults to 0.01
    attr_accessor :xff

    # Step intervals allowed between updates before the value of the
    # data source is considered Unknown and returned as nil.
    # Defaults to 6
    attr_accessor :heartbeat

    # Default name used to reference the SimpleRRD data source
    # Defaults to 'dataset'
    @@DS_NAME = 'data_source'

    # Class accessor for @@DS_NAME
    #
    # @return [String] Value of default SimpleRRD data source name
    def self.DS_NAME
        @@DS_NAME
    end

    # Create a SimpleRRD wrapper for RRD file.
    #
    # @param [String] file_path Filesystem path of the RRD file.
    # @param [Time] timestamp @when value for #create, #update, and
    # #read methods.  Defaults to Now.
    #
    # @return [SimpleRRD] Resulting SimpleRRD object.
    # @return [nil] nil if file exists but is not SimpleRRD-compatible.
    def initialize(file_path=nil, timestamp=self.class.now)
        @path = file_path
        @when = timestamp
        @values = []

        # Set default ivars
        @step       = 60
        @kind       = :GAUGE
        @min        = 'U'
        @max        = 'U'
        @duration   = 157680000    # 5 years
        @xff        = 0.50
        @heartbeat  = 6

        read_in_ivars if readable? # File already exists, so read in ivars
    end
    
    # Set a new @path for the underlying RRD file.
    #
    # @return [String] New @path value
    def path=(new_path=nil)
        @path = new_path
        read_in_ivars if @path && readable?
        return @path
    end

    # Are the Instance Variables all valid?
    #
    # @return [boolean] true if object's instance variables are valid
    def valid?
        return !path_empty? && @when.class == Time && @step.to_i > 0 && 
               @kind && @@SUPPORTED_KINDS.include?(@kind.to_s.upcase.to_sym) &&
               (@min.is_a?(Numeric) || @min == 'U') &&
               (@max.is_a?(Numeric) || @max == 'U') &&
               (@min == 'U' || @max == 'U' || @min < @max) &&
               @duration.to_i > 0 && @xff.to_f > 0.0 && @xff.to_f < 1.0 &&
               @heartbeat.to_i > 0
    end

    # == CRUD Operations

    # Create RRD file using current configuration.
    #
    # @return [boolean] false if already exists, configuration invalid,
    # not writable by EUID, or rrdcreate fails.
    # @return [nil] nil if @path is nil or empty.
    def create
        return nil if path_empty?
        return false if exists? || !valid? || mkdir_if_needed == false

        # Start 1 step back
        timestamp = @when-@step

        # Initialize array of arguments to pass to rrdtool
        rrd_options_arr = [path,
            "--start", timestamp.to_i.to_s,
            "--step", @step.to_i.to_s]

        # Construct DS and RRD arguments for rrdtool
        hb = (@heartbeat * @step) # Convert to rrdtool-style heartbeat
        # Convert @min/@max, as necessary
        min_val = @min.to_s
        max_val = @max.to_s
        if @kind.to_sym != :GAUGE # Calculate per-second rates
            min_val = @min.to_f/@step if @min.is_a?(Numeric)
            max_val = @max.to_f/@step if @max.is_a?(Numeric)
        end
        rrd_options_arr << "DS:#{ds_name}:#{@kind}:#{hb}:#{min_val}:#{max_val}"
        rrd_options_arr << "RRA:LAST:#{@xff}:1:#{@duration/@step}"

        # Daily Rollups, currently unused by this class
        if (@step < 86400)
            steps = 86400/@step
            rows = @duration/86400
            rrd_options_arr << "RRA:AVERAGE:#{@xff}:#{steps}:#{rows}"
            rrd_options_arr << "RRA:MIN:#{@xff}:#{steps}:#{rows}"
            rrd_options_arr << "RRA:MAX:#{@xff}:#{steps}:#{rows}"
        end

        return (RRD.create *rrd_options_arr).nil?
    end

    # Read Array of values from RRD file.
    #
    # Will attempt to read a value every @step seconds, but falls back
    # to rrdtool-provided resolution if unable to match specified @step.
    #
    # @param [Integer] seconds Seconds worth of values to fetch.
    #
    # @return [Array<Float>] Values from RRD file, stores copy in @values.
    # @return [nil] nil if object is not valid (@path empty, no file found.)
    def read(seconds=86400)
        return nil if !exists? || !readable?
        user_requested_step = @step+0

        # Set @step to Greatest Common Denominator of @step and RRD's step
        @step = @step.to_i.gcd(info_rrd['step'])

        (fstart, fend, dsname, data, resolution) = RRD.fetch(path, 'LAST',
            "--resolution", @step,
            "--start", (@when-@step).to_i.to_s,
            "--end", (@when+seconds).to_i.to_s)

        # Assume resolution is exactly as the user requested.
        resolution = user_requested_step if resolution.nil?

        # The Ruby RRD bindings fetch too many rows, so trim the last one.
        @values = data.flatten[0..((seconds/resolution))-1]

        # Unknown and NaN values are converted to nil.
        @values.map!{|item| (item.nan? && item.class == Float) ? nil : item}

        if @kind.to_sym != :GAUGE # Calculate from per-second rates
            @values.map!{|i| (i.nil? || i.nan?) ? i : i*resolution}
        end

        # Return the values with resolution matching @step, if simple:
        if (resolution > @step && (resolution % @step) == 0)
            padded_values = []
            @values.each do |value|
                padded_values += [value] * (resolution / @step)
            end
            @values = padded_values
        else # Otherwise, the client can cope with it.
            @step = resolution
        end
        return @values
    end

    # Write Array of values to RRD file.
    #
    # @param [Array<Float,Integer,nil>] value Values to write.
    #
    # @return [boolean] false if @path if file is not writable by EUID,
    # or if object is not valid or if @when is less than or equal to
    # #last_update_time (due to rrdtool restrictions).
    # @return [nil] nil if @path is nil or empty, or file does not exist.
    def update(values=[])
        return nil if !exists?
        return false if !valid? || !writable? || @when <= last_update_time

        rrd_options_arr = [path]
        timestamp = @when+0
        values.each do |value|
            value = 'U' if (value.nil? || value == '')
            rrd_options_arr << "#{timestamp.to_i}:#{value}"
            timestamp += @step
        end
        return (RRD.update *rrd_options_arr).nil?
    end

    # Delete RRD file.
    #
    # @return [boolean] false if object is not valid or if file is not
    # writable by EUID.
    # @return [nil] nil if @path is nil or empty or file does not exist.
    def delete
        return nil if !exists?
        return false if !writable?
        File.delete(path)
        return true
    end

    # == RRD File Information

    # Get RRD file's last update time.
    #
    # @return [Time] RRD file's last update time.
    # @return [nil] nil if file does not exist, is not an RRD file,
    # object variables are invalid, or file has no updates.
    def last_update_time
        val = info_rrd['last_update']
        return nil if val.nil?
        return Time.at(val)
    end

    # == File Management

    # Does the RRD file exist?
    #
    # @return [boolean] true if RRD file currently exists at @path.
    # @return [nil] nil if @path is nil or empty.
    def exists?
        return nil if path_empty?
        return File.exists?(path)
    end

    # RRD file exists, is readable, and configured as a SimpleRRD.
    #
    # @return [boolean] true if readable by EUID and in proper format.
    # @return [nil] nil if @path is nil or empty or file does not exist.
    def readable?
        return nil if !exists?
        return info_rrd['rra[0].cf'] == 'LAST'
    end

    # File exists and is writable.
    #
    # @return [boolean] true if RRD at @path writable by current object w/EUID.
    # @return [nil] nil if RRD file does not exist.
    def writable?
        return nil if !exists?
        return File.writable?(path) && readable?
    end

private

    # == Instance Variable Verification

    # Is the path instance variable empty (unspecified)
    #
    # @return [boolean] true if @path is nil or an empty string.
    def read_in_ivars
            ds          = ds_name
            info        = info_rrd
            @step       = info['step'].to_i
            @kind       = info["ds[#{ds}].type"].to_s.upcase.to_sym
            @min        = info["ds[#{ds}].min"]
            @max        = info["ds[#{ds}].max"].to_f
            @duration   = info['rra[0].rows'].to_i * @step
            @xff        = info['rra[0].xff'].to_f
            @heartbeat  = (info["ds[#{ds}].minimal_heartbeat"].to_f/
                           @step).ceil

            # Simplify min/max values so humans may comprehend them
            @min        = @min.to_f * @step if @min != 'U' && @kind != :GAUGE
            @max        = @max.to_f * @step if @max != 'U' && @kind != :GAUGE
    end

    # == Instance Variable Verification

    # Is the path instance variable empty (unspecified)
    #
    # @return [boolean] true if @path is nil or an empty string.
    def path_empty?
        return path.nil? || path == ''
    end

    # == RRD File Information

    # Get info on RRD file from rrdtool info.
    #
    # @return [Hash] rrdinfo parameters and values. (Empty if not readable.)
    def info_rrd
        begin
            return RRD.info(path)
        rescue
            return {}
        end
    end

    # Get ds-name from #info_rrd.
    #
    # @return [String] value of ds-name name in RRD file.
    # @return [String] 'dataset' if RRD file does not exist.
    # @return [nil] nil if ds-name name not readable.
    def ds_name
        return @@DS_NAME if !exists?
        info_rrd.keys.sort.each do |key|
            return Regexp.last_match(1) if key =~ /^ds\[(.*)\]\.type$/
        end
        return nil
    end

    # == File Management

    # Get the RRD file's directory.
    #
    # @return [string] Directory portion of @path.
    def directory
        return File.dirname(path.to_s)
    end

    # Is the existing ancestor directory writable?
    #
    # @return [boolean] true if existing ancestor directory is writable.
    # @return [nil] nil if @path is nil or an empty string.
    def directory_writable?
        return nil if path_empty?
        dir = directory
        while dir != '/' && dir != '.'
            break if File.exists?(dir)
            dir = File.dirname(dir)
        end
        return true if (File.writable?(dir))
        return false
    end

    # Create #directory if it does not exist.
    #
    # @return [boolean] false if effective user lacks permissions.
    # @return [nil] nil if directory exists and is writable.
    def mkdir_if_needed
        dir = directory
        return nil if File.exists?(dir) && File.writable?(dir)
        return FileUtils.mkdir_p(dir) if directory_writable?
        return false
    end
end
