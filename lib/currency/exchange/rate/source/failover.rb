# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

require 'currency/exchange/rate/source'


module Currency
module Exchange
class Rate
class Source

# Gets Rates from primary source, if primary fails, attempts secondary source.
#
class Failover < ::Currency::Exchange::Base
  # Gets Rates from primary Source.
  # Use secondary if primary fails.
  attr_accessor :primary

  attr_accessor :secondary

  def initialize(*opt)
    super(*opt)
  end
  
  def name
    "failover(#{primary.name}, #{secondary.name})"
  end


  def clear_rates
    @primary.clear_rates
    @secondary.clear_rates
    super
  end
  

  def get_rate(c1, c2, time)
    rate = @primary.get_rate(c1, c2, time)
    unless rate
      $stderr.put "Failover: primary failed for get_rate(#{c1}, #{c2}, #{time})"
      rate = @secondary.get_rate(c1, c2, time)
    end
    unless rate
      raise("Failover: secondary failed for get_rate(#{c1}, #{c2}, #{time})")
    end

    rate
  end

 
end # class

end # class
end # class
end # module
end # module


