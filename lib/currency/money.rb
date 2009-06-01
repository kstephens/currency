# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

require 'rational' # to_r

#
# Represents an amount of money in a particular currency.
#
# A Money object stores its value using a scaled Integer representation
# and a Currency object.
#
# A Money object also has a time, which is used in conversions
# against historical exchange rates.
#
class Currency::Money
    include Comparable

    @@default_time = nil
    def self.default_time
      @@default_time
    end
    def self.default_time=(x)
      @@default_time = x
    end

    @@empty_hash = { }
    @@empty_hash.freeze

    #
    # DO NOT CALL THIS DIRECTLY:
    #
    # See Currency.Money() function.
    #
    # Construct a Money value object 
    # from a pre-scaled external representation:
    # where x is a Float, Integer, String, etc.
    #
    # If a currency is not specified, Currency.default is used.
    #
    #    x.Money_rep(currency) 
    #
    # is invoked to coerce x into a Money representation value.
    #
    # For example:
    #
    #    123.Money_rep(:USD) => 12300
    #
    # Because the USD Currency object has a #scale of 100
    #
    # See #Money_rep(currency) mixin.
    #
    def initialize(x, currency = nil, time = nil, exact = nil)
      opts ||= @@empty_hash

      raise ArgumentError, "exact (#{exact.inspect}) is not true, false or nil" unless 
        exact == true || exact == false || exact == nil

      exact = true if exact.nil?

      # Set ivars.
      currency = ::Currency::Currency.get(currency)
      @currency = currency
      @time = time || ::Currency::Money.default_time
      @time = ::Currency::Money.now if @time == :now
      @exact = exact
      case x
      when String
        if currency
          m = currency.parser_or_default.parse(x, :currency => currency)
        else
          m = ::Currency::Parser.default.parse(x)
        end
        @currency = m.currency unless @currency
        @time = m.time if m.time
        @rep = m.rep
        @exact &&= m.exact?
      else
        @currency = ::Currency::Currency.default unless @currency
        @rep, exact = x.Money_rep(@currency)
        @exact &&= exact
      end
      raise TypeError, "@exact (#{@exact.inspect}) is not true or false" unless @exact == true || @exact == false
    end

    # Returns a Time.new
    # Can be modifed for special purposes.
    def self.now
      Time.new
    end

    # Compatibility with Money package.
    def self.us_dollar(x)
      self.new(x, :USD)
    end


    # Compatibility with Money package.
    def cents
      @rep
    end


    # Construct from post-scaled internal representation.
    def self.new_rep(r, currency = nil, time = nil, exact = nil)
      x = self.new(0, currency, time, exact)
      x.set_rep(r)
      x
    end


    # Construct from post-scaled internal representation.
    # using the same currency.
    #
    #    x = Currency.Money("1.98", :USD)
    #    x.new_rep(123) => USD $1.23
    #
    # time defaults to self.time.
    # exact defaults to self.exact?.
    def new_rep(r, time = nil, exact = nil)
      time ||= @time
      exact = @exact if exact.nil?
      x = self.class.new(0, @currency, time, exact)
      x.set_rep(r)
      x
    end


    # Do not call this method directly.
    # CLIENTS SHOULD NEVER CALL set_rep DIRECTLY.
    # You have been warned in ALL CAPS.
    def set_rep(r) # :nodoc:
      r = r.to_i unless Integer === r
      @rep = r
    end

    # Do not call this method directly.
    # CLIENTS SHOULD NEVER CALL set_time DIRECTLY.
    # You have been warned in ALL CAPS.
    def set_time(time) # :nodoc:
      @time = time
    end

    # Returns the Money representation (usually an Integer).
    def rep
      @rep
    end

    # Get the Money's Currency.
    def currency
      @currency
    end

    # Get the Money's time.
    def time
      @time
    end


    # Is the Money value known to be exact?
    def exact?
      ! ! @exact
    end


    # Coerce Money value into exact Money value.
    def exact
      if @exact == false
        new_rep(@rep, nil, true)
      else
        self
      end
    end


    # Coerce Money value into an inexact Money value.
    def inexact
      if @exact == true
        new_rep(@rep, nil, false)
      else
        self
      end
    end


    # Convert Money to another Currency.
    # currency can be a Symbol or a Currency object.
    # If currency is nil, the Currency.default is used.
    #
    # time argument is currently unsupported.
    def convert(currency, time = nil)
      currency = ::Currency::Currency.default if currency.nil?
      currency = ::Currency::Currency.get(currency) unless currency.kind_of?(Currency)
      if @currency == currency
        self
      else
        time = self.time if time == :money
        ::Currency::Exchange::Rate::Source.current.convert(self, currency, time)
      end
    end


    # Hash for hash table: both value and currency.
    # See #eql? below.
    def hash
      @rep.hash ^ @currency.hash
    end

    # True if money values have the same value and currency.
    def eql?(x)
      self.class == x.class && 
        @rep == x.rep && 
        @currency == x.currency
    end

    # True if money values have the same value and currency and exactness.
    def ==(x)
       self.class == x.class && 
        @rep == x.rep && 
        @currency == x.currency &&
        @exact == x.exact?
    end

    # Compares Money values.
    # Will convert x to self.currency before comparision.
    #
    # NOTE: due to rate conversion rounding the following may not
    # be true.
    #
    #   usd = Money(123.45, :USD)
    #   cad = usd.convert(:CAD)
    #   (usd <=> cad) == 0
    def <=>(x)
      rep_diff(x) <=> 0
    end

    # Compares self and x.
    # If difference between reps is <= tolerance, returns 0.
    def cmp(x, tolerance = 0)
      diff = rep_diff(x)
      if tolerance != 0
        tolerance, e = tolerance.Money_rep(@currency) 
      end
      diff.abs <= tolerance ? 0 : diff <=> 0
    end

    # Returns the difference in currencies.
    # Will convert x to self.currency before comparision.
    #
    # NOTE: due to rate conversion rounding the following may not
    # be true.
    #
    #   usd = Money(123.45, :USD)
    #   cad = usd.convert(:CAD)
    #   usd.rep_diff(cad) == 0
    def rep_diff(x)
      if @currency == x.currency
        @rep - x.rep
      else
        @rep - x.convert(@currency, @time).rep
      end
    end


    #   - Money(c1) => Money(c1)
    #
    # Negates a Money value.
    def -@
      new_rep(- @rep)
    end

    #    Money(c1) + (Money(c2) | Number) => Money(c1)
    #
    # Right side may be coerced to left side's Currency.
    def +(x)
      r, e = x.Money_rep(@currency)
      # $stderr.puts "   #{self.class}#+  x = #{x.inspect} r = #{r.inspect}, e = #{e.inspect}" 
      new_rep(@rep + r, nil, @exact && e)
    end

    #    Money(c1) - (Money(c2) | Number) => Money(c1)
    #
    # Right side may be coerced to left side's Currency.
    def -(x)
      x, e = x.Money_rep(@currency)
      new_rep(@rep - x, nil, @exact && e)
    end

    #    Money * Number => Money
    #
    # Right side must be Number.
    def *(x)
      new_rep(@rep * x, nil, @exact && (! Integer === e))
    end

    #    Money(c1) / Money(c2) => Rational | Integer (exact)
    #    Money(c1) / Number => Money(c1) (inexact)
    #
    # Right side must be Money or Number.
    # Right side may be coerced to left side's Currency.
    # Right side Integers are not coerced to Float before
    # division.
    def /(x)
      case x
      when self.class
        x, e = x.Money_rep(@currency)
        r = (@rep.to_r) / (x.to_r)
        r = r.numerator if r.denominator == 1
        r
      else
        new_rep(@rep / x, nil, @exact && (! Integer === x))
      end
    end

    # Formats the Money value as a String using the Currency's Formatter.
    def format(*opt)
      @currency.format(self, *opt)
    end

    # Formats the Money value as a String.
    def to_s(*opt)
      @currency.format(self, *opt)
    end

    # Coerces the Money's value to a Float.
    # May cause loss of precision.
    def to_f
      @rep.to_f / @currency.scale
    end

    # Coerces the Money's value to a Rational
    # No loss of precision.
    def to_r
      @rep.to_r / @currency.scale
    end

    # Coerces the Money's value to an Integer.
    # Fractional units (e.g.: US cents) are discarded.
    # May cause loss of precision.
    def to_i
      @rep / @currency.scale
    end

    # True if the Money's value is zero.
    def zero?
      @rep == 0
    end

    # True if the Money's value is greater than zero.
    def positive?
      @rep > 0
    end
    
    # True if the Money's value is less than zero.
    def negative?
      @rep < 0
    end

    # Returns the Money's value representation in another currency.
    def Money_rep(currency, time = nil)
      # Attempt conversion?
      r = if @currency != currency || (time && @time != time)
	x = self.convert(currency, time)
        [ x.rep, x.exact? ]
        # raise ::Currency::Exception::Generic, "Incompatible Currency: #{@currency} != #{currency}"
      else
        [ @rep, @exact ]
      end
      # $stderr.puts "  #{self.class}#Money_rep self = #{[ @rep, @currency, @exact ].inspect}, #{currency.inspect}, #{time.inspect}"
      # $stderr.puts "     #{r.inspect}"
      r
    end

    # Basic inspection, with symbol, currency code and time.
    # The standard #inspect method is available as #inspect_deep.
    def inspect(*opts)
      self.format(:symbol => true, :code => true, :time => true)
    end

    # How to alias a method defined in an object superclass in a different class:
    define_method(:inspect_deep, Object.instance_method(:inspect))
    # How call a method defined in a superclass from a method with a different name:
    #    def inspect_deep(*opts)
    #      self.class.superclass.instance_method(:inspect).bind(self).call 
    #    end

end # class

