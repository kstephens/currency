# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.


# This class formats a Money value as a String.
# Each Currency has a default Formatter.
class Currency::Formatter
  # The underlying object for Currency::Formatter#format.
  # This object is cloned and initialized with strings created
  # from Formatter#format.
  # It handles the Formatter#format string interpolation.
  class Template
    @@empty_hash = { }
    @@empty_hash.freeze

    # The template string.
    attr_accessor :template

    # The Currency::Money object being formatted.
    attr_accessor :money
    # The Currency::Currency object being formatted.
    attr_accessor :currency

    # The sign: '-' or nil.
    attr_accessor :sign
    # The whole part of the value, with thousands_separator or nil.
    attr_accessor :whole
    # The fraction part of the value, with decimal_separator or nil.
    attr_accessor :fraction
    # The currency symbol or nil.
    attr_accessor :symbol
    # The currency code or nil.
    attr_accessor :code

    
    def initialize(opts = @@empty_hash)
      opts.each_pair{ | k, v | self.send("#{k}=", v) }
    end


    # Sets the template string and uncaches the template_proc.
    def template=(x)
      if @template != x
        @template_proc = nil
      end
      @template = x
    end


    # Defines a the self._format template procedure using
    # the template as a string to be interpolated.
    def template_proc(template = @template)
      return @template_proc if @template_proc
      @template_proc = template || ''
      # @template_proc = @template_proc.gsub(/[\\"']/) { | x | "\\" + x }
      @template_proc = "def self._format; \"#{@template_proc}\"; end"
      self.instance_eval @template_proc
      @template_proc
    end


    # Formats the current state using the template.
    def format
      template_proc
      _format
    end
  end


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

  # A template string used to format a money value.
  # Defaults to:
  # 
  #   '#{code}#{code && " "}#{symbol}#{sign}#{whole}#{fraction}'
  attr_accessor :template


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
    x
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
    @template = '#{code}#{code && " "}#{symbol}#{sign}#{whole}#{fraction}'

    opt.each_pair{ | k, v | self.send("#{k}=", v) }
  end


  def currency=(x) # :nodoc:
    # DO NOTHING!
  end


  # Sets the template and the Template#template.
  def template=(x)
    if @template_object
      @template_object.template = x
    end
    @template = x
  end


  # Returns the Template object.
  def template_object
    return @template_object if @template_object

    @template_object = Template.new
    @template_object.template = @template if @template
    # $stderr.puts "template.template = #{@template_object.template.inspect}"
    @template_object.template_proc # pre-cache before clone.

    @template_object
  end


  def _format(m, currency = nil) # :nodoc:
    # Get currency.
    currency ||= m.currency

    # Setup template
    tmpl = self.template_object.clone
    # $stderr.puts "template.template = #{tmpl.template.inspect}"
    tmpl.money = m
    tmpl.currency = currency

    # Get scaled integer representation for this Currency.
    # $stderr.puts "m.currency = #{m.currency}, currency => #{currency}"
    x = m.Money_rep(currency)

    # Remove sign.
    x = - x if ( neg = x < 0 )
    tmpl.sign = neg ? '-' : nil
    
    # Convert to String.
    x = x.to_s
    
    # Keep prefixing "0" until filled to scale.
    while ( x.length <= currency.scale_exp )
      x = "0" + x
    end
    
    # Insert decimal place.
    whole = x[0 .. currency.format_left] 
    fraction = x[currency.format_right .. -1]
 
    # Do thousands.
    x = whole
    if @thousands && (@thousands_separator && ! @thousands_separator.empty?)
      x.reverse!
      x.gsub!(/(\d\d\d)/) {|y| y + @thousands_separator}
      x.sub!(/#{@thousands_separator}$/,'')
      x.reverse!
    end
    
    # Put whole and fractional parts.
    tmpl.whole = x
    tmpl.fraction = @cents && @decimal_separator ? @decimal_separator + fraction : nil

 
    # Add symbol?
    tmpl.symbol = @symbol ? ((@html && currency.symbol_html) || currency.symbol) : nil

    
    # Suffix with currency code.
    tmpl.code = @code ? _format_Currency(currency) : nil
    
    # Ask template to format the components.
    tmpl.format
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

