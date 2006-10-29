module Currency
  # Represents a method of converting between two currencies
  # TODO: 
  #  Create an ExchangeRateLoader class.
  #  Create an ExchangeRateLoader subclass that interfaces to xe.com or other FX quote source.
  class CurrencyExchangeTest < CurrencyExchange
    @@instance = nil
    def self.instance(*opts)
      @@instance ||= self.new(*opts)
    end

    # Sample constant.
    def self.USD_CAD; 1.1708; end

    def load_exchange_rate(c1, c2)
      # $stderr.puts "load_exchange_rate(#{c1}, #{c2})"
      rate = 0.0
      if ( c1.code == :USD && c2.code == :CAD )
        rate = self.class.USD_CAD
      end
      rate > 0 ? ExchangeRate.new(c1, c2, rate, self.class.name) : nil
    end
  end

  # END MODULE
end

# Install as current
Currency::CurrencyExchange.default = Currency::CurrencyExchangeTest.instance

