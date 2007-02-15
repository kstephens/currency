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

    def initialize(opt = { })
      @name = nil
      @verbose = nil unless defined? @verbose

      @rate = { }
      opt.each_pair{|k,v| self.send("#{k}=", v)}
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
    end


    # Flush any cached Rate between Currency c1 and c2.
    def clear_rate(c1, c2, time, recip = true)
      time = normalize_time(time)
    end


    # Returns the cached Rate between Currency c1 and c2 at a given time.
    #
    # Time is normalized using #normalize_time(time)
    #
    # Subclasses can override this method to implement
    # rate expiration rules.
    #
    def rate(c1, c2, time)
      raise("Subclass responsibility: #{self.class}#rate")
    end


    # Determines and creates the Rate between Currency c1 and c2.
    #
    # May attempt to use a pivot currency to bridge between
    # rates.
    #
    def get_rate(c1, c2, time)
      raise("Subclass responsibility: #{self.class}#get_rate")
    end

    # Returns a base Rate.
    #
    # Subclasses are required to implement this method.
    def get_rate_base(c1, c2, time)
      raise Exception::UnknownRate.new("Subclass responsibility: #{self.class}#get_rate_base")
    end


    # Returns an array of all base Rates.
    def get_all_rate_bases(time)
      raise Exception::UnknownRate.new("Subclass responsibility: #{self.class}#get_all_rate_bases")
    end


    # Called by implementors to construct new Rate objects.
    def new_rate(c1, c2, c1_to_c2_rate, time = nil, derived = nil)
      rate = Rate.new(c1, c2, c1_to_c2_rate, name, time, derived)
      # $stderr.puts "new_rate = #{rate}"
      rate
    end


    # Normalizes rate time to a quantitized value.
    # For example: a time_quant_size of 60 * 60 * 24 will
    # truncate a rate time to a particular day.
    #
    # Subclasses can override this method.
    def normalize_time(time)
      time && Currency::Exchange::TimeQuantitizer.current.quantitize_time(time)
    end
  

    # Returns a simple string rep of an Exchange object.
    def to_s
      "#<#{self.class.name} #{self.name && self.name.inspect}>"
    end

  end # class

  
end # module
end # module

