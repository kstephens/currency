# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

module Currency
  #include Currency::Exceptions

  # Represents a currency.
  #
  class Currency
    # Returns the ISO three-letter currency code as a symbol.
    # e.g. :USD, :CAD, etc.
    attr_reader :code

    # The Currency's scale factor.  
    # e.g: the :USD scale factor is 100.
    attr_reader :scale

    # The Currency's scale factor.  
    # e.g: the :USD scale factor is 2, where 10 ^ 2 == 100.
    attr_reader :scale_exp

    # Used by Formatter.
    attr_reader :format_right

    # Used by Formatter.
    attr_reader :format_left

    # The Currency's symbol. 
    # e.g: USD symbol is '$'
    attr_accessor :symbol

    # The Currency's symbol as HTML.
    # e.g: EUR symbol is '&#8364;' (:html &#8364; :) or '&euro;' (:html &euro; :)
    attr_accessor :symbol_html

    # The default Formatter.
    attr_accessor :formatter

    # The default parser.
    attr_accessor :parser


    # Create a new currency.
    # This should only be called from Currency::Currency::Factory.
    def initialize(code, symbol = nil, scale = 100)
      self.code = code
      self.symbol = symbol
      self.scale = scale
      @formatter = nil
      @parser = nil
    end


    # Returns the Currency object from the default Currency::Currency::Factory
    # by its 3-letter uppercase Symbol name, such as :USD, or :CAD.
    def self.get(code)
      # $stderr.puts "#{self}.get(#{code.inspect})"
      return nil unless code
      return code if code.kind_of?(::Currency::Currency)
      Factory.default.get_by_code(code)
    end


    # Internal method for converting currency codes to internal
    # Symbol format.
    def self.cast_code(x)
     x = x.upcase.intern if x.kind_of?(String)
     raise Exception::InvalidCurrencyCode.new(x) unless x.kind_of?(Symbol)
     raise Exception::InvalidCurrencyCode.new(x) unless x.to_s.length == 3
     x
    end


    # Returns the hash of the Currency's code.
    def hash
      @code.hash
    end


    # Returns true if the Currency's are equal.
    def eql?(x)
      self.class == x.class && @code == x.code
    end


    # Returns true if the Currency's are equal.
    def ==(x)
      self.class == x.class && @code == x.code
    end


    # Clients should never call this directly.
    def code=(x)
      x = self.class.cast_code(x) unless x.nil?
      @code = x
      #$stderr.puts "#{self}.code = #{@code}"; x
    end


    # Clients should never call this directly.
    def scale=(x)
      @scale = x
      return x if x.nil?
      @scale_exp = Integer(Math.log10(@scale));
      @format_right = - @scale_exp
      @format_left = @format_right - 1
      x
    end


    # Parse a Money string in this Currency.
    #
    # See Currency::Parser#parse.
    #
    def parse(str, *opt)
      parser_or_default.parse(str, *opt)
    end


    def parser_or_default
      (@parser || ::Currency::Parser.default)
    end


    # Formats the Money value as a string using the current Formatter.
    # See Currency::Formatter#format.
    def format(m, *opt)
       formatter_or_default.format(m, *opt)
    end


    def formatter_or_default
      (@formatter || ::Currency::Formatter.default)
    end


    # Returns the Currency code as a String.
    def to_s
      @code.to_s
    end


    # Returns the default Factory's currency.
    def self.default
      Factory.default.currency
    end


    # Sets the default Factory's currency.
    def self.default=(x)
      x = self.get(x) unless x.kind_of?(self)
      Factory.default.currency = x
    end


    # Returns the USD Currency.
    def self.USD
      Factory.default.USD
    end


    # Returns the CAD Currency.
    def self.CAD
      Factory.default.CAD
    end


    # Returns the EUR Currency.
    def self.EUR
      Factory.default.EUR
    end


    # Returns the GBP Currency.
    def self.GBP
      Factory.default.GBP
    end

  end # class
  
end # module

