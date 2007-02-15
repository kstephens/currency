# Base class for rate providers.
# Assumes that rate sources provide more than one rate per query.
#

require 'currency/exchange/rate'

class Currency::Exchange::Rate::Source
  # The URI used to access the rate source.
  attr_accessor :uri
  
  # This providers name is the same as its #uri.
  def name
    uri
  end
  
  def initialize(*opt)
    @processing_rates = false
    @rates = nil
    super(*opt)
  end
  
  
  # Clears current rates.
  def clear_rates
    @rates = nil
  end
  
  
  # Returns current base Rates or calls load_rates to load them from the source.
  def rates
    @rates ||= load_rates
  end
  
  
  # Returns an array of base Rates from the rate source.
  #
  def load_rates
    raise('Subclass responsiblity')
  end


  # Called by implementors to construct new Rate objects.
  def new_rate(c1, c2, c1_to_c2_rate, time = nil, derived = nil)
    c1 = ::Currency::Currency.get(c1)
    c2 = ::Currency::Currency.get(c2)
    rate = ::Currency::Exchange::Rate.new(c1, c2, c1_to_c2_rate, self.name, time, derived)
    # $stderr.puts "new_rate = #{rate}"
    rate
  end
  
end # class



