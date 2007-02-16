# -*- ruby -*-
#
# = Currency::Currency
#
# Represents a currency.
#
#

module Currency
  #include Currency::Exceptions

  class Currency
    # Returns the ISO 3-letter currency code as a symbol.
    # E.g. :USD, :CAD, etc.
    attr_reader :code

    # The Currency's scale factor.  
    # E.g: the :USD scale factor is 100.
    attr_reader :scale

    # The Currency's scale factor.  
    # E.g: the :USD scale factor is 2, where 10 ^ 2 == 100.
    attr_reader :scale_exp

    attr_reader :format_right
    attr_reader :format_left

    # The Currency's symbol. 
    # E.g: USD symbol is '$'
    attr_accessor :symbol

    # The Currency's symbol as HTML.
    # e.g: EUR symbol is 
    attr_accessor :symbol_html

    # The default formatter.
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
    # Options:
    #   :currency => Currency object.
    # Look for a matching currency code at the beginning or end of the string.
    # If the currency does not match IncompatibleCurrency is raised.
    #
    def parse(str, *opt)
      x = str
      opt = Hash[*opt]

      md = nil # match data

      # $stderr.puts "'#{x}'.Money_rep(#{self})"
      
      # Handle currency code at front of string.
      if (md = /^([A-Z][A-Z][A-Z])\s*(.*)$/.match(x)) != nil 
        curr = Factory.default.get_by_code(md[1])
        x = md[2]
        if curr != self
          if opt[:currency] && opt[:currency] != curr
            raise Exception::IncompatibleCurrency.new("#{str} #{opt[:currency].code}")
          end
          return Money.new(x, curr);
        end
        # Handle currency code at end of string.
      elsif (md = /^(.*)\s*([A-Z][A-Z][A-Z])$/.match(x)) != nil 
        curr = Factory.default.get_by_code(md[2])
        x = md[1]
        if curr != self
          if opt[:currency] && opt[:currency] != curr
            raise Exception::IncompatibleCurrency.new("#{str} #{opt[:currency].code}")
          end
          return Money.new(x, curr);
        end
      end

      # Remove placeholders and symbol.
      x = x.gsub(/[, ]/, '')
      x = x.sub(@symbol, '') if @symbol

      # Match: whole Currency value.
      if x =~ /^[-+]?(\d+)\.?$/
        # $stderr.puts "'#{self}'.parse(#{str}) => EXACT"
        x.to_i.Money_rep(self)
        
        # Match: fractional Currency value.
      elsif (md = /^([-+]?)(\d*)\.(\d+)$/.match(x)) != nil
        sign = md[1]
        whole = md[2]
        part = md[3]
        
        # $stderr.puts "'#{self}'.parse(#{str}) => DECIMAL (#{sign} #{whole} . #{part})"
        
        if part.length != self.scale
          
          # Pad decimal places with additional '0'
          while part.length < self.scale_exp
            part << '0'
          end
          
          # Truncate to Currency's decimal size. 
          part = part[0..(self.scale_exp - 1)]
          
          # $stderr.puts "  => INEXACT DECIMAL '#{whole}'"
        end
        
        # Put the string back together:
        #   #{sign}#{whole}#{part}
        whole = sign + whole + part
        # $stderr.puts "  => REP = #{whole}"
        
        x = whole.to_i

        x = Money.new_rep(x, opt[:currency], opt[:time])
      else
        # $stderr.puts "'#{self}'.parse(#{str}) => ??? '#{x}'"
        #x.to_f.Money_rep(self)
        raise Exception::InvalidMoneyString.new("#{str} #{self}")
      end
    end


    # Format a Money object as a String.
    @@default_formatter = nil
    def self.default_formatter; @@default_formatter; end
    def self.default_formatter=(x); @@default_formatter = x; end

    def format(m, *opt)
       (@formatter || (@@default_formatter ||= ::Currency::Formatter.new)).format(m, *opt)
    end


    #def to_s
    #  @code.to_s
    #end


    # Returns the default Factory's currency.
    def self.default
      Factory.default.currency
    end


    # Sets the default Factory's currency.
    def self.default=(x)
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

