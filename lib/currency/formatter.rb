# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.


# This class formats a Money value as a String.
# Each Currency has a default Formatter.
class Currency::Formatter
  # Defaults to ','
  attr_accessor :thousands_separator

  # Defaults to '.'
  attr_accessor :decimal_separator

  # If true, insert _thousands_separator_ between each 3 digits in the whole value.
  attr_accessor :thousands

  # If true, append _decimal_separator_ and decimal digits after whole value.
  attr_accessor :cents
  
  # If true, prefix value with currency symbol.
  attr_accessor :symbol

  # If true, append currency code.
  attr_accessor :code

  # If true, use html formatting.
  #
  #   Currency::Money(12.45, :EUR).to_s(:html => true; :code => true)
  #   => "&#8364;12.45 <span class=\"currency_code\">EUR</span>"

  attr_accessor :html


  # If passed true, formats for an input field (i.e.: as a number).
  def as_input_value=(x)
    if x
      self.thousands_separator = ''
      self.decimal_separator = '.'
      self.thousands = false
      self.cents = true
      self.symbol = false
      self.code = false
      self.html = false
    end
  end


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
    @thousands_separator = ','
    @decimal_separator = '.'
    @thousands = true
    @cents = true
    @symbol = true
    @code = false
    @html = false

    opt.each_pair{ | k, v | self.send("#{k}=", v) }
  end


  def currency=(x) # :nodoc:
    # DO NOTHING!
  end


  def _format(m, currency = nil) # :nodoc:
    # Get currency.
    currency ||= m.currency

    # Get scaled integer representation for this Currency.
    # $stderr.puts "m.currency = #{m.currency}, currency => #{currency}"
    x = m.Money_rep(currency)

    # Remove sign.
    x = - x if ( neg = x < 0 )
    
    # Convert to String.
    x = x.to_s
    
    # Keep prefixing "0" until filled to scale.
    while ( x.length <= currency.scale_exp )
      x = "0" + x
    end
    
    # Insert decimal place.
    whole = x[0 .. currency.format_left] 
    decimal = x[currency.format_right .. -1]
 
    # Do commas
    x = whole
    if @thousands && (@thousands_separator && ! @thousands_separator.empty?)
      x.reverse!
      x.gsub!(/(\d\d\d)/) {|y| y + @thousands_separator}
      x.sub!(/#{@thousands_separator}$/,'')
      x.reverse!
    end
    
    x << @decimal_separator + decimal if @cents && @decimal_separator
    
    # Put sign back.
    x = '-' + x if neg
    
    # Add symbol?
    x = ((@html && currency.symbol_html) || currency.symbol || '') + x if @symbol
    
    # Suffix with currency code.
    if @code
      x << (' ' + _format_Currency(currency))
    end
    
    x
  end


  def _format_Currency(c) # :nodoc:
    x = ''
    x << '<span class="currency_code">' if @html
    x << c.code.to_s
    x << '</span>' if @html
    x
  end


  @@empty_hash = { }
  @@empty_hash.freeze

  # Format a Money object as a String.
  # 
  #   m = Money.new("1234567.89")
  #   m.to_s(:code => true, :symbol => false)
  #     => "1,234,567.89 USD"
  #
  def format(m, opt = @@empty_hash)
    fmt = self

    unless opt.empty? 
      fmt = fmt.clone
      opt.each_pair{ | k, v | fmt.send("#{k}=", v) }
    end

    # $stderr.puts "format(opt = #{opt.inspect})"
    fmt._format(m, opt[:currency]) # Allow override of current currency.
  end

end # class

