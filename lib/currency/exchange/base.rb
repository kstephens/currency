module Currency
  # Represents a method of converting between two currencies
  # TODO: 
  #  Create an ExchangeRateLoader class.
  #  Create an ExchangeRateLoader subclass that interfaces to xe.com or other FX quote source.
  class CurrencyExchange
    @@default = nil
    def self.default 
      @@default ||= self.new
    end
    def self.default=(x)
      @@default = x
    end

    def initialize(*opt)
      @exchange_rate = { }
    end 

    def convert(m, c2, c1 = nil)
      c1 = m.currency if c1 == nil
      if ( c1 == c2 )
        m
      else
        Money.new(exchange_rate(c1, c2).convert(m, c1), c2)
      end
    end

    def clear_exchange_rates
      @exchange_rate.empty!
    end

    def clear_exchange_rate(c1, c2, recip = true)
      @exchange_rate[c1.code.to_s + c2.code.to_s] = nil
      @exchange_rate[c2.code.to_s + c1.code.to_s] = nil if recip
    end

    def exchange_rate(c1, c2)
      (@exchange_rate[c1.code.to_s + c2.code.to_s] ||= load_exchange_rate(c1, c2)) ||
      (@exchange_rate[c2.code.to_s + c1.code.to_s] ||= load_exchange_rate(c2, c1))
    end

    
    def load_exchange_rate(c1, c2)
      raise "Subclass responsibility: load_exchange_rate"
    end
  end

  # END MODULE
end

