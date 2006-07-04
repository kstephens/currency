module Currency
  class CurrencyFactory
    # Default factory.
    @@default = nil
    def self.default
      @@default ||= CurrencyFactory.new
    end

    def initialize
      @currency_by_code = { }
      @currency_by_symbol = { }
      @currency = nil
      @USD = nil    
      @CAD = nil
    end

    # Lookup table by code
    def get_by_code(x)
     x = Currency.cast_code(x)
     # $stderr.puts "get_by_code(#{x})"
     @currency_by_code[x] ||= load(Currency.new(x))
    end

    # Lookup table by symbol
    def get_by_symbol(symbol)
      @currency_by_symbol[symbol] ||= load(Currency.new(nil, symbol))
    end

    def load(currency)
      # $stderr.puts "BEFORE: load(#{currency.code})"

      # SAMPLE CODE
      if currency.code == :USD || currency.symbol == '$'
	# $stderr.puts "load('USD')"
        currency.code= :USD
        currency.symbol= '$'
        currency.scale= 100
      elsif currency.code == :CAD
        # $stderr.puts "load('CAD')"
        currency.symbol= '$'
        currency.scale= 100
      else
        currency.symbol= nil
        currency.scale= 100
      end
  
      # $stderr.puts "AFTER: load(#{currency.inspect})"

      install(currency)
    end

    def install(currency)
      @currency_by_symbol[currency.symbol] ||= currency unless currency.symbol.nil?
      @currency_by_code[currency.code] = currency
    end

    # Standard Currencys
    def USD
      @USD ||= self.get_by_code(:USD)
    end

    def CAD
      @CAD ||= self.get_by_code(:CAD)
    end

    # Default Currency
    def currency
      @currency ||= self.USD
    end
  end
  # END MODULE
end

