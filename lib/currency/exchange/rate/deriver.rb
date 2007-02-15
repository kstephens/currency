# -*- ruby -*-
#
# = Currency::Exchange::Rate::Deriver
#
# The Currency::Exchange::Rate::Deriver class calculates derived rates
# from base Rates from a rate Source by pivoting against a pivot currency or by
# generating reciprocals.
#
#

module Currency
module Exchange
class Rate

# Represents a method of calculating derived rates between any two currency pairs,
# using any available base rates from a Source.
class Deriver < ::Currency::Exchange::Base

  # The source for base rates.
  attr_accessor :source
  
  # Currency to use as pivot for deriving rate pairs.
  # Defaults to the source.pivot_currency.
  attr_accessor :pivot_currency
  

  def name
    source.name
  end


  def initialize(opt = { })
    @verbose = nil unless defined? @verbose
    @pivot_currency = nil
    
    @rate = { }
    opt.each_pair{|k,v| self.send("#{k}=", v)}
  end 


  # Flush all cached Rates.
  def clear_rates
    @rate.clear
  end


  def pivot_currency
    @source.pivot_currency || :USD
  end


  # Return list of known Rates.
  # source may have more Rates underneath this object.
  def rates
    @rate.values
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
        rate = new_rate(c1, c2, 
                        c1_to_c2_rate, 
                        rate_1.date || rate_2.date || time, 
                        "pivot(#{pc.code},#{rate_1.derived || "#{rate_1.c1.code}#{rate_1.c2.code}"},#{rate_2.derived || "#{rate_2.c1.code}#{rate_2.c2.code}"})")
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


  # Returns a cached base Rate.
  #
  def get_rate_base_cached(c1, c2, time)
    rate = (@rate[c1.code.to_s + c2.code.to_s + (time || '')] ||= get_rate_base(c1, c2, time))
    rate
  end


  # Returns a base Rate from the Source.
  def get_rate_base(c1, c2, time)
    if c1 == c2
      new_rate(c1, c2, 1.0, time, "identity")
    else
      source.get_rate_base(c1, c2, time)
    end
  end


  # Returns a simple string rep of an Exchange object.
  def to_s
    "#<#{self.class.name} #{self.source.inspect}>"
  end

end # class

  
end # class
end # module
end # module


