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
    
    def initialize(*opt)
      @name = nil
      @rate = { }
      opt = Hash[*opt]
      opt.each{|k,v| self.send(k, v)}
    end 

    # Converts Money m in Currency c1 to a new
    # Money value in Currency c2.
    def convert(m, c2, c1 = nil)
      c1 = m.currency if c1 == nil
      if ( c1 == c2 )
        m
      else
        Money.new(rate(c1, c2).convert(m, c1), c2)
      end
    end

    # Flush all cached Rate.
    def clear_rates
      @rate.clear
    end

    # Flush any cached Rate between Currency c1 and c2.
    def clear_rate(c1, c2, recip = true)
      @rate[c1.code.to_s + c2.code.to_s] = nil
      @rate[c2.code.to_s + c1.code.to_s] = nil if recip
    end

    # Returns the Rate between Currency c1 and c2.
    #
    # This will call #get_rate(c1, c2) if the
    # Rate has not already been cached.
    #
    # Subclasses can override this method to implement
    # rate expiration rules.
    #
    def rate(c1, c2)
      (@rate[c1.code.to_s + c2.code.to_s] ||= get_rate(c1, c2)) ||
      (@rate[c2.code.to_s + c1.code.to_s] ||= get_rate(c2, c1))
    end

    
    # Determines and creates the Rate between Currency c1 and c2.
    #
    # Subclasses are required to implement this method.
    def get_rate(c1, c2)
      raise Exception::UnknownRate.new("Subclass responsibility: get_rate")
    end

    # Returns a simple string rep of an Exchange object.
    def to_s
      "#<#{self.class.name} #{self.name && self.name.inspect}>"
    end

  end # class

  
end # module
end # module

