# -*- ruby -*-
#
# = Currency::Money
#
# Represents an amount of money in a particular currency.
#
# A Money object stores its value using a scaled Integer representation
# and a Currency object.
#
#

module Currency

  # Use this function instead of Money#new:
  #
  #    Currency::Money("12.34", :CAD)
  #
  # not
  #
  #    Currency::Money.new("12.34", :CAD)
  #
  # See Money#new.
  def self.Money(*opts)
    Money.new(*opts)
  end

  class Money
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
    # Construct a Money value object 
    # from a pre-scaled external representation:
    # where x is a Float, Integer, String, etc.
    #
    # If a currency is not specified, Currency#default is used.
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
    # See Currency#Money() function.
    #
    def initialize(x, currency = nil, time = nil)
      opts ||= @@empty_hash

      # Xform currency
      currency = Currency.default if currency.nil?
      currency = Currency.get(currency) unless currency.kind_of?(Currency)

      # Set ivars
      @currency = currency;
      @rep = x.Money_rep(@currency)
      @time = time || Money.default_time
      @time = Time.new if @time == :now

      # Handle conversion of "USD 123.45"
      if @rep.kind_of?(Money)
        @currency = @rep.currency
        @rep = @rep.rep
      end
    end


    # Compatibility with Money package.
    def self.us_dollar(x)
      self.new(x, :USD)
    end


    # Compatibility with Money package.
    def cents
      @rep
    end


    # Construct from post-scaled internal representation
    def self.new_rep(r, currency = nil, time = nil)
      x = self.new(0, currency, time)
      x.set_rep(r)
      x
    end

    # Construct from post-scaled internal representation
    # using the same currency.
    #    x = Currency::Money.new("1.98", :USD)
    #    x.new_rep(100) => "$1.00 USD"
    #
    def new_rep(r, time = nil)
      time ||= @time
      x = self.class.new(0, @currency, time)
      x.set_rep(r)
      x
    end

    # Do not call this method directly.
    # CLIENTS SHOULD NEVER CALL set_rep DIRECTLY.
    # You have been warned in ALL CAPS.
    def set_rep(r)
      r = r.to_i unless r.kind_of?(Integer)
      @rep = r
    end

    # Do not call this method directly.
    # CLIENTS SHOULD NEVER CALL set_time DIRECTLY.
    # You have been warned in ALL CAPS.
    def set_time(time)
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

    # Convert Money to another Currency.
    # currency can be a Symbol or a Currency object.
    # If currency is nil, the Currency.default is used.
    def convert(currency, time = nil)
      currency = Currency.default if currency.nil?
      currency = Currency.get(currency) unless currency.kind_of?(Currency)
      if @currency == currency
        self
      else
        Exchange.current.convert(self, currency, time)
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

    # True if money values have the same value and currency.
    def ==(x)
       self.class == x.class && 
        @rep == x.rep && 
        @currency == x.currency
    end

    # Compares Money values.
    # Will convert x currency before comparision.
    def <=>(x)
      if @currency == x.currency
        @rep <=> x.rep
      else
        @rep <=> convert(@currency, @time).rep
      end
    end


    #   - Money => Money
    #
    # Negates a Money value.
    def -@
      new_rep(- @rep)
    end

    #    Money + (Money | Number) => Money
    #
    # Right side may be coerced to left side's Currency.
    def +(x)
      new_rep(@rep + x.Money_rep(@currency))
    end

    #    Money - (Money | Number) => Money
    #
    # Right side may be coerced to left side's Currency.
    def -(x)
      new_rep(@rep - x.Money_rep(@currency))
    end

    #    Money * Number => Money
    #
    # Right side must be Number.
    def *(x)
       new_rep(@rep * x)
    end

    #    Money / Money => Number (ratio)
    #    Money / Number => Money
    #
    # Right side must be Money or Number.
    # Right side Integers are not coerced to Float before
    # division.
    def /(x)
      if x.kind_of?(self.class)
        (@rep.to_f) / (x.Money_rep(@currency).to_f)
      else
        new_rep(@rep / x)
      end
    end

    # Formats the Money value as a String.
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
      Float(@rep) / @currency.scale
    end

    # Coerces the Money's value to an Integer.
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
      if @currency != currency || (time && @time != time)
	self.convert(currency, time).rep
        # raise("Incompatible Currency: #{@currency} != #{currency}")
      else
        @rep
      end
    end

    # Basic inspection, with symbol and currency code.
    # The standard #inspect method is available as #inspect_deep.
    def inspect(*opts)
      self.format(:with_symbol, :with_currency).inspect
    end

    # How to alias a method defined in an object superclass in a different class:
    define_method(:inspect_deep, Object.instance_method(:inspect))
    # How call a method defined in a superclass from a method with a different name:
    #    def inspect_deep(*opts)
    #      self.class.superclass.instance_method(:inspect).bind(self).call 
    #    end

  end # class

end # module
