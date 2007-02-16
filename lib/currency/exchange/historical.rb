# Gets historical rates.
#


require 'currency/exchange/historical/rate'

module Currency
module Exchange
 class Historical < Base

    # Select specific rate source.
    # Defaults to nil
    attr_accessor :source


    # This Exchange's name is the same as its #uri.
    def name
      "historical #{source.inspect}"
    end


    def initialize(*opt)
      @rate_cache = nil
      super(*opt)
    end


    def clear_rates
      @rate_cache && @rate_cache.clear
      super
    end


    # Loads 
    def get_rate(c1, c2, time)
      rates = get_rates(time)
 
      # Use USD as pivot to convert between c1 and c2.
      if ( c1.code == PIVOT_CURRENCY && (r2 = rates_pivot[c2.code]) )
        rate = r2
      elsif ( c2.code == PIVOT_CURRENCY && (r1 = rates_pivot[c2.code]) )
        rate = 1.0 / r1
      elsif ( (r1 = rates_pivot[c1.code]) && (r2 = rates_pivot[c2.code]) )
        rate = r2 / r1
      end

      # $stderr.puts "Historical Rate: #{c1.code} / #{c2.code} = #{rate}"

      rate > 0 ? new_rate(c1, c2, rate, @rate_timestamp) : nil
    end


    # Return a list of base rates.
    def get_rates(time)
      raw_rates = get_raw_rates(time)

      rates = raw_rates.each do | raw_rate |
        rate = new_rate(raw_rate.c1, rate_rate.c2, raw_rate.rate, raw_rate.date)
      end

      rates
    end


    def get_raw_rates(time, src)
      condition_sql = 'date_0 < ? AND date_1 <= ?'
      conditions = [ time, time ]
      if src
        condition_sql += ' AND src = ?'
        conditions << src
      end

      conditions_value.unshift(conditions_sql)
      raw_rates = Rate.find(:all, :condition => conditions)

      raw_rates
    end

  end # class

end # module
end # module


# Install as default.
# Currency::Exchange.default = Currency::Exchange::Xe.instance

