# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

module Currency

# This class parses a Money value from a String.
# Each Currency has a default Parser.
class Parser

  # The default Currency to use if no Currency is specified.
  attr_accessor :currency

  # If true and a parsed string contains a ISO currency code
  # that is not the same as currency,
  # #parse() will raise IncompatibleCurrency.
  # Defaults to false.
  attr_accessor :enforce_currency

  # The default Time to use if no Time is specified in the string.
  attr_accessor :time

  @@default = nil
  # Get the default Formatter.
  def self.default
    @@default || self.new
  end


  # Set the default Formatter.
  def self.default=(x)
    @@default = x
  end
  

  def initialize(opt = { })
    opt.each_pair{ | k, v | self.send("#{k}=", v) }
  end


  def _parse(str) # :nodoc:
    x = str

    # Get currency.
    # puts "str = #{str.inspect}, @currency = #{@currency}"

    md = nil # match data

    # $stderr.puts "'#{x}'.Money_rep(#{self})"
    
    # $stderr.puts "x = #{x}"
    convert_currency = nil
    # Handle currency code at front of string.
    if (md = /([A-Z][A-Z][A-Z])/.match(x)) 
      curr = ::Currency::Currency.get(md[1])
      x = md.pre_match + md.post_match
      if @currency && @currency != curr
        if @enforce_currency
          raise Exception::IncompatibleCurrency.new("#{str.inspect} #{@currency.code}")
        end
        convert_currency = @currency
      end
      currency = curr
    else
      currency = @currency || ::Currency::Currency.default
      currency = ::Currency::Currency.get(currency)
    end
    
    # Remove placeholders and symbol.
    x = x.gsub(/[, ]/, '')
    symbol = currency.symbol # FIXME
    x = x.gsub(symbol, '') if symbol
    
    # $stderr.puts "x = #{x.inspect}"
    # Match: whole Currency value.
    if md = /^([-+]?\d+)\.?$/.match(x)
      # $stderr.puts "'#{self}'.parse(#{str}) => EXACT"
      x = Money.new_rep(md[1].to_i * currency.scale, currency, @time)
      
      # Match: fractional Currency value.
    elsif md = /^([-+]?)(\d*)\.(\d+)$/.match(x)
      sign = md[1]
      whole = md[2]
      part = md[3]
      
      # $stderr.puts "'#{self}'.parse(#{str}) => DECIMAL (#{sign} #{whole} . #{part})"
      
      if part.length != currency.scale
        
        # Pad decimal places with additional '0'
        while part.length < currency.scale_exp
          part << '0'
        end
        
        # Truncate to Currency's decimal size. 
        part = part[0 ... currency.scale_exp]
        
        # $stderr.puts "  => INEXACT DECIMAL '#{whole}'"
      end
      
      # Put the string back together:
      #   #{sign}#{whole}#{part}
      whole = sign + whole + part
      # $stderr.puts "  => REP = #{whole}"
      
      x = whole.to_i
      
      x = Money.new_rep(x, currency, @time)
    else
      # $stderr.puts "'#{self}'.parse(#{str}) => ??? '#{x}'"
      #x.to_f.Money_rep(self)
      raise Exception::InvalidMoneyString.new("#{str.inspect} #{currency} #{x.inspect}")
    end

    # Do conversion.
    if convert_currency
      x = x.convert(convert_currency)
    end


    x
  end


  @@empty_hash = { }
  @@empty_hash.freeze

  # Parse a Money string in this Currency.
  #
  #   "123.45".money       # Using default Currency.
  #   => $123.45 USD
  #
  #   "123.45 USD".money   # Explicit Currency.
  #   => $123.45 USD
  #
  #   "123.45 CAD".money
  #   => $123.45 CAD
  #  
  #   "123.45 CAD".money(:USD)  # Incompatible explicit Currency.
  #     !!! "123.45 CAD" USD (Currency::Exception::IncompatibleCurrency)
  #
  def parse(str, opt = @@empty_hash)
    prs = self

    unless opt.empty? 
      prs = prs.clone
      opt.each_pair{ | k, v | prs.send("#{k}=", v) }
    end
    
    prs._parse(str)
  end

end # class

end # module

