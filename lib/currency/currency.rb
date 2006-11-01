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
    # Create a new currency.
    # This should only be called from Currency::CurrencyFactory.
    def initialize(code, symbol = nil, scale = 100)
      self.code = code
      self.symbol = symbol
      self.scale = scale
    end

    # Returns the Currency object from the default CurrencyFactory
    # by its 3-letter uppercase Symbol name, such as :USD, or :CAD.
    def self.get(code)
      CurrencyFactory.default.get_by_code(code)
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

    # Get the Currency's code.
    def code
      @code
    end


    # Client should never call this directly.
    def code=(x)
      x = self.class.cast_code(x) unless x.nil?
      @code = x
      #$stderr.puts "#{self}.code = #{@code}"; x
    end

    # Get the Currency's scale factor.  
    # E.g: the :USD scale factor is 100.
    def scale
      @scale
    end

    # Client should never call this directly.
    def scale=(x)
      @scale = x
      return x if x.nil?
      @scale_exp = Integer(Math.log10(@scale));
      @format_right = - @scale_exp
      @format_left = @format_right - 1
      x
    end

    # Get the Currency's scale factor.  
    # E.g: the :USD scale factor is 2, where 10 ^ 2 == 100.
    def scale_exp
      @scale_exp
    end

    # Get the Currency's symbol. 
    # E.g. :USD, :CAD, etc.
    def symbol
      @symbol
    end

    # Client should never call this directly.
    def symbol=(x)
      @symbol = x
    end

    # Parse a Money string.
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
        curr = CurrencyFactory.default.get_by_code(md[1])
        x = md[2]
        if curr != self
          if opt[:currency] && opt[:currency] != curr
            raise Exception::IncompatibleCurrency.new("#{str} #{opt[:currency].code}")
          end
          return Money.new(x, curr);
        end
        # Handle currency code at end of string.
      elsif (md = /^(.*)\s*([A-Z][A-Z][A-Z])$/.match(x)) != nil 
        curr = CurrencyFactory.default.get_by_code(md[2])
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

        x = Money.new_rep(x, opt[:currency])
      else
        # $stderr.puts "'#{self}'.parse(#{str}) => ??? '#{x}'"
        #x.to_f.Money_rep(self)
        raise Exception::InvalidMoneyString.new("#{str} #{self}")
      end
    end

    # Format a Money object.
    def format(m, *opt)
      opt = opt.flatten

      # Get scaled integer representation for this Currency.
      x = m.Money_rep(self)

      # Remove sign.
      x = - x if ( neg = x < 0 )

      # Convert to String.
      x = x.to_s

      # Keep prefixing "0" until filled to scale.
      while ( x.length <= @scale_exp )
        x = "0" + x
      end

      # Insert decimal place
      whole = x[0..@format_left] 
      decimal = x[@format_right..-1]

      # Do commas
      x = whole
      unless opt.include?(:no_thousands)
        x.reverse!
        x.gsub!(/(\d\d\d)/) {|y| y + ','}
        x.sub!(/,$/,'')
        x.reverse!
      end

      x << '.' + decimal unless opt.include?(:no_cents) || opt.include?(:no_decimal)

      # Put sign back.
      x = "-" + x if neg

      # Add symbol?
      x = (@symbol || '') + x unless opt.include?(:no_symbol)

      # Suffix currency code.
      if opt.include?(:with_currency)
        x << ' '
        x << '<span class="currency">' if opt.include?(:html)
        x << @code.to_s
        x << '</span>' if opt.include?(:html)
      end

      x
    end

    #def to_s
    #  @code.to_s
    #end

    # Returns the default CurrencyFactory's currency.
    def self.default
      CurrencyFactory.default.currency
    end
    # Sets the default CurrencyFactory's currency.
    def self.default=(x)
      CurrencyFactory.default.currency = x
    end

    # Returns the USD Currency.
    def self.USD
      CurrencyFactory.default.USD
    end

    # Returns the CAD Currency.
    def self.CAD
      CurrencyFactory.default.CAD
    end

  end # class
  
end # module

