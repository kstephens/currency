require 'currency/exchange/rate'

module Currency
module Exchange
class Rate
module Source

# Base class for rate data providers.
# Assumes that rate sources provide more than one rate per query.
class Provider << Base
  # The URI used to access the rate source.
  attr_accessor :uri
  
  # The name is the same as its #uri.
  alias :name :uri 
  

  # Returns current base Rates or calls load_rates to load them from the source.
  def rates
    @rates ||= load_rates
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

end # class


end # module
end # class
end # module
end # module


