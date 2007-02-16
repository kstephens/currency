require 'currency/exchange/rate'

module Currency
module Exchange
class Rate

# Base class for rate data providers.
# Assumes that rate sources provide more than one rate per query.
class Source
  # The URI used to access the rate source.
  attr_accessor :uri
  
  # Currency to use as pivot for deriving rate pairs.
  # Defaults to :USD.
  attr_accessor :pivot_currency
  

  # The name is the same as its #uri.
  alias :name :uri 
  

  def initialize(opt = { })
    @processing_rates = false
    @rates = nil
    @pivot_currency ||= :USD
    
    # super(opt)
  end
  
  
  # Clears current rates.
  def clear_rates
    @rates = nil
    @currencies = nil
  end
  
  
  # Returns current base Rates or calls load_rates to load them from the source.
  def rates
    @rates ||= load_rates
  end
  
  
  # Returns a list of Currency that the rate source provides.
  def currencies
    @currencies ||= rates.collect{| r | [ r.c1.code, r.c2.code ]}.flatten.uniq
  end

  # Returns an array of base Rates from the rate source.
  #
  # Subclasses must define this method.
  def load_rates
    raise('Subclass responsiblity')
  end


  # Return a matching base rate?
  def get_rate(c1, c2, time)
    matching_rates = rates.select do | rate |
      rate.c1 == c1 &&
      rate.c2 == c2 &&
      (! time || normalize_time(rate.date) == time)
    end
    matching_rates[0]
  end

  alias :get_rate_base :get_rate


  # Called by implementors to construct new Rate objects.
  def new_rate(c1, c2, c1_to_c2_rate, time = nil, derived = nil)
    c1 = ::Currency::Currency.get(c1)
    c2 = ::Currency::Currency.get(c2)
    rate = ::Currency::Exchange::Rate.new(c1, c2, c1_to_c2_rate, self.name, time, derived)
    # $stderr.puts "new_rate = #{rate}"
    rate
  end
  

  # Normalizes rate time to a quantitized value.
  #
  # Subclasses can override this method.
  def normalize_time(time)
    time && ::Currency::Exchange::TimeQuantitizer.current.quantitize_time(time)
  end
  

  def to_s
    "#<#{self.class.name} #{name.inspect}>"
  end

  def inspect
    to_s
  end
end # class


end # class
end # module
end # module


