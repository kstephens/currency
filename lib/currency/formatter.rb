module Currency

class Formatter
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
  attr_accessor :html


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


  def currency=(x)
    # DO NOTHING!
  end


  def _format(m, currency = nil)
    # Get currency.
    currency ||= m.currency

    # Get scaled integer representation for this Currency.
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
    x = ((@html ? currency.symbol_html : currency.symbol) || '') + x if @symbol
    
    # Suffix with currency code.
    if @code
      x << ' '
      x << '<span class="currency_code">' if @html
      x << currency.code.to_s
      x << '</span>' if @html
    end
    
    x
  end


  # Format a Money object as a String.
  def format(m, opt = { })
    fmt = self.clone

    opt.each_pair{ | k, v | fmt.send("#{k}=", v) }

    fmt._format(m, opt[:currency]) # Allow override of current currency.
  end

end # class

end # module
