# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

module Currency
class Currency

  class Factory
    @@default = nil

    # Returns the default Currency::Factory.
    def self.default
      @@default ||= self.new
    end
    # Sets the default Currency::Factory.
    def self.default=(x)
      @@default = x
    end


    def initialize(*opts)
      @currency_by_code = { }
      @currency_by_symbol = { }
      @currency = nil

      # Standards
      @USD = nil    
      @CAD = nil
      @EUR = nil
      @GBP = nil
    end


    # Lookup Currency by code.
    def get_by_code(x)
      x = ::Currency::Currency.cast_code(x)
      # $stderr.puts "get_by_code(#{x})"
      @currency_by_code[x] ||= install(load(Currency.new(x)))
    end


    # Lookup Currency by symbol.
    def get_by_symbol(symbol)
      @currency_by_symbol[symbol] ||= install(load(::Currency::Currency.new(nil, symbol)))
    end


    # This method initializes a Currency object as
    # requested from #get_by_code or #get_by_symbol.
    #
    # This method must initialize:
    #
    #    currency.code
    #    currency.scale
    # 
    # Optionally:
    #
    #    currency.symbol
    #    currency.symbol_html
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
      elsif currency.code == :EUR
        # $stderr.puts "load('CAD')"
        currency.symbol = nil
        currency.symbol_html = '&#8364;'
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


    # Standard Currency: Euro, :EUR.
    def EUR
      @EUR ||= self.get_by_code(:EUR)
    end


    # Standard Currency: Great Britain Pound, :GBP.
    def GBP
      @GBP ||= self.get_by_code(:GBP)
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

end # class
end # module



