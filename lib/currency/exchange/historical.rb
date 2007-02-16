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


    def get_raw_rates(time, source)
      rate = Rate.new(:date => time, :source => source)
      raw_rates = rate.find_matching_this(:all)
      raw_rates
    end

  end # class

end # module
end # module


# Install as default.
# Currency::Exchange.default = Currency::Exchange::Xe.instance

