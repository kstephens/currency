module Currency
  class CurrencyFactory
    @@default = nil

    # Returns the default CurrencyFactory.
    def self.default
      @@default ||= CurrencyFactory.new
    end
    # Sets the default CurrencyFactory.
    def self.default=(x)
      @@default = x
    end

    def initialize(*opts)
      @currency_by_code = { }
      @currency_by_symbol = { }
      @currency = nil
      @USD = nil    
      @CAD = nil
    end

    # Lookup Currency by code.
    def get_by_code(x)
      x = Currency.cast_code(x)
      # $stderr.puts "get_by_code(#{x})"
      @currency_by_code[x] ||= install(load(Currency.new(x)))
    end

    # Lookup Currency by symbol.
    def get_by_symbol(symbol)
      @currency_by_symbol[symbol] ||= install(load(Currency.new(nil, symbol)))
    end

    # This method initializes a Currency object as
    # requested from #get_by_code or #get_by_symbol.
    #
    # This method must define:
    #
    #    currency.code
    #    currency.symbol
    #    currency.scale
    #
    # Subclasses that provide Currency metadata should override this method.
    # For example, loading Currency metadata from a database or YAML file.
    def load(currency)
      # $stderr.puts "BEFORE: load(#{currency.code})"

      # Basic
      if currency.code == :USD || currency.symbol == '$'
	# $stderr.puts "load('USD')"
        currency.code = :USD
        currency.symbol = '$'
        currency.scale = 100
      elsif currency.code == :CAD
        # $stderr.puts "load('CAD')"
        currency.symbol = '$'
        currency.scale = 100
      else
        currency.symbol = nil
        currency.scale = 100
      end
  
      # $stderr.puts "AFTER: load(#{currency.inspect})"

      currency
    end

    # Installs a new Currency for #get_by_symbol and #get_by_code.
    def install(currency)
      raise Exception::UnknownCurrency.new() unless currency
      @currency_by_symbol[currency.symbol] ||= currency unless currency.symbol.nil?
      @currency_by_code[currency.code] = currency
    end

    # Standard Currency: US Dollars, :USD.
    def USD
      @USD ||= self.get_by_code(:USD)
    end

    # Standard Currency: Canadian Dollars, :CAD.
    def CAD
      @CAD ||= self.get_by_code(:CAD)
    end

    # Returns the default Currency.
    # Defaults to self.USD.
    def currency
      @currency ||= self.USD
    end

    # Sets the default Currency.
    def currency=(x)
      @currency = x
    end

  end # class
end # module



