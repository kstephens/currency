# -*- ruby -*-
#
# = Currency::Exchange::Base
#
# The Currency::Exchange::Base class is the base class for
# currency exchange rate providers.
#
# Currency::Exchange::Base subclasses are Currency::Exchange::Rate
# factories.
#

module Currency
module Exchange

  # Represents a method of converting between two currencies
  class Base

    # The name of this Exchange.
    attr_accessor :name

    # If true, this Exchange will log information.
    attr_accessor :verbose

    # Currency to use as pivot for non-exact matching
    # rate pairs.
    # Defaults to :USD
    attr_accessor :pivot_currency

    # Rate time quantitization size.
    # Defaults to 1 day.
    attr_accessor :time_quant_size

    # Rate time quantization offset in seconds.
    # This is applied to epoch time before quantization.
    # If nil, uses Time#utc_offset.
    # Defaults to nil.
    attr_accessor :time_quant_offset


    def initialize(*opt)
      @name = nil
      @pivot_currency    ||= :USD
      @time_quant_size   ||= 60 * 60 * 24
      @time_quant_offset ||= nil

      @rate = { }
      opt = Hash[*opt]
      opt.each{|k,v| self.send(k, v)}
    end 


    # Converts Money m in Currency c1 to a new
    # Money value in Currency c2.
    def convert(m, c2, time = nil, c1 = nil)
      c1 = m.currency if c1 == nil
      time = m.time if time == nil
      time = normalize_time(time)
      if c1 == c2 && normalize_time(m.time) == time
        m
      else
        ::Currency::Money(rate(c1, c2, time).convert(m, c1), c2, time)
      end
    end


    # Flush all cached Rate.
    def clear_rates
      @rate.clear
    end


    # Flush any cached Rate between Currency c1 and c2.
    def clear_rate(c1, c2, time, recip = true)
      time = normalize_time(time)
      @rate[c1.code.to_s + c2.code.to_s + (time || '')] = nil
    end


    # Returns the cached Rate between Currency c1 and c2 at a given time.
    #
    # Time is normalized using #normalize_time(time)
    #
    # This will call #get_rate(c1, c2, time) if the
    # Rate has not already been cached.
    #
    # Subclasses can override this method to implement
    # rate expiration rules.
    #
    def rate(c1, c2, time)
      time = normalize_time(time)
      (@rate[c1.code.to_s + c2.code.to_s + (time || '')] ||= get_rate(c1, c2, time))
    end


    # Called by implementors to construct new Rate objects.
    def new_rate(c1, c2, c1_to_c2_rate, time = nil, derived = nil)
      rate = Rate.new(c1, c2, c1_to_c2_rate, self, time, derived)
      # $stderr.puts "new_rate = #{rate}"
      rate
    end


    # Determines and creates the Rate between Currency c1 and c2.
    #
    # May attempt to use a pivot currency to bridge between
    # rates.
    #
    def get_rate(c1, c2, time)
      rate = get_rate_reciprocal(c1, c2, time)

      # Attempt to use pivot_currency to bridge
      # between Rates.
      unless rate
        pc = Currency.get(pivot_currency)

        if pc &&
           (rate_1 = get_rate_reciprocal(c1, pc, time)) && 
           (rate_2 = get_rate_reciprocal(pc, c2, time))
          c1_to_c2_rate = rate_1.rate * rate_2.rate
          rate = new_rate(c1, c2, c1_to_c2_rate, time, "pivot #{pc.code}, #{rate_1.derived}, #{rate_2.derived}")
        end
      end

      rate
    end


    # Get a matching base rate or its reciprocal.
    def get_rate_reciprocal(c1, c2, time)
      rate = get_rate_base_cached(c1, c2, time)
      unless rate
        if rate = get_rate_base_cached(c2, c1, time)
          rate = (@rate[c1.code.to_s + c2.code.to_s + (time || '')] ||= rate.reciprocal)
        end
      end
      
      rate
    end


    # Returns a cached base rate.
    #
    def get_rate_base_cached(c1, c2, time)
      rate = (@rate[c1.code.to_s + c2.code.to_s + (time || '')] ||= get_rate_base(c1, c2, time))
      rate
    end


    # Returns a base rate.
    #
    # Subclasses are required to implement this method.
    def get_rate_base(c1, c2, time)
      raise Exception::UnknownRate.new("Subclass responsibility: get_rate_base")
    end


    # Normalizes rate time to a quantitized value.
    # For example: a time_quant_size of 60 * 60 * 24 will
    # truncate a rate time to a particular day.
    #
    # Subclasses can override this method.
    def normalize_time(time)
      # If nil, then nil.
      return time unless time

      # Get bucket parameters.
      was_utc = time.utc?
      quant_offset = time_quant_offset
      quant_offset ||= time.utc_offset
      quant_size = time_quant_size.to_i

      # Get offset from epoch.
      time = time.tv_sec

      # Remove offset (timezone)
      time -= quant_offset

      # Truncate to quantitize size.
      time = (time.to_i / quant_size) * quant_size

      # Add offset (timezone)
      time += quant_offset

      # Convert back to Time object.
      time = Time.at(time)

      # Normalize to day?
      if quant_size == 60 * 60 * 24 
        if was_utc
          time = time.getutc
          time = Time.utc(time.year, time.month, time.day, 0, 0, 0, 0)
        else
          time = Time.local(time.year, time.month, time.day, 0, 0, 0, 0)
        end
      end

      # Convert back to UTC?
      time = time.getutc if was_utc

      time
    end
    

    # Returns a simple string rep of an Exchange object.
    def to_s
      "#<#{self.class.name} #{self.name && self.name.inspect}>"
    end

  end # class

  
end # module
end # module

