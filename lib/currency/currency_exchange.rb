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

    def initialize
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

    def exchange_rate(c1, c2)
      (@exchange_rate[c1.code.to_s + c2.code.to_s] ||= load_exchange_rate(c1, c2)) ||
      (@exchange_rate[c2.code.to_s + c1.code.to_s] ||= load_exchange_rate(c2, c1))
    end

    
    def self.USD_CAD; 1.1708; end
    def load_exchange_rate(c1, c2)
      # $stderr.puts "load_exchange_rate(#{c1}, #{c2})"
      rate = 0.0
      if ( c1.code == :USD && c2.code == :CAD )
        rate = self.class.USD_CAD
      end
      rate > 0 ? ExchangeRate.new(c1, c2, rate, "SAMPLE") : nil
    end
  end

  class ExchangeRate
    def initialize(c1, c2, c1_to_c2_rate, source = "UNKNOWN", recip = true)
      @c1 = c1
      @c2 = c2
      @rate = c1_to_c2_rate
      @source = source
      @reciprocal = recip
    end

    def c1
      @c1
    end

    def c2
      @c2
    end

    def rate
      @rate
    end

    def source
      @source
    end

    def convert(m, c1)
      m = m.to_f	
      if ( @c1 == c1 )
        # $stderr.puts "Converting #{@c1} #{m} to #{@c2} #{m * @rate} using #{@rate}"
        m * @rate
      else
        # $stderr.puts "Converting #{@c2} #{m} to #{@c1} #{m / @rate} using #{1.0 / @rate}; recip"
        m / @rate
      end
    end
  end

  # END MODULE
end

