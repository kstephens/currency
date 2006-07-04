module Currency

  # Represents an amount of money in a particular currency.
  #
  # NOTE: do we need to store a time, so we can use
  # historical FX rates to convert?
  #
  class Money
    include Comparable


    # Construct from a pre-scaled external representation:
    # Float, Integer, String, etc.
    # See #Money_rep(currency) mixin.
    def initialize(x, currency = nil)
      # Xform currency
      currency = Currency.default if currency.nil?
      currency = Currency.get(currency) unless currency.kind_of?(Currency)

      # Set ivars
      @currency = currency;
      @rep = x.Money_rep(@currency)

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
    def cents
      @rep
    end


    # Construct from post-scaled internal representation
    def self.new_rep(r, currency = nil)
      x = self.new(0, currency)
      x.set_rep(r)
      x
    end
    def new_rep(r)
      x = self.class.new(0, @currency)
      x.set_rep(r)
      x
    end

    # CLIENTS SHOULD NEVER CALL set_rep DIRECTLY!
    def set_rep(r)
      r = r.to_i unless r.kind_of?(Integer)
      @rep = r
    end

    def Money_rep(currency)
      $stderr.puts "@currency != currency (#{@currency.inspect} != #{currency.inspect}" unless @currency == currency
      @rep
    end

    def rep
      @rep
    end

    # Get the money's Currency
    def currency
      @currency
    end

    # Convert Money to another Currency
    def convert(currency)
      currency = Currency.default if currency.nil?
      currency = Currency.get(currency) unless currency.kind_of?(Currency)
      if @currency == currency
        self
      else
        CurrencyExchange.default.convert(self, currency)
      end
    end

    # Relational operations on Money values.
    def eql?(x)
      @rep == x.rep && @currency == x.currency
    end

    def ==(x)
      @rep == x.rep && @currency == x.currency
    end

    def <=>(x)
      if @currency == x.currency
        @rep <=> x.rep
      else
        @rep <=> convert(@currency).rep
      end
    end

    # Operations on Money values.


    def -@
      # - Money => Money
      new_rep(- @rep)
    end

    # Right side maybe coerced to Money.
    def +(x)
      # Money + (Number|Money) => Money
      new_rep(@rep + x.Money_rep(@currency))
    end

    # Right side maybe coerced to Money.
    def -(x)
      # Money - (Number|Money) => Money
      new_rep(@rep - x.Money_rep(@currency))
    end

    # Right side must be number
    def *(x)
      # Money * Number => Money
      new_rep(@rep * x)
    end

    # Right side must be number or Money
    def /(x)
      if x.kind_of?(self.class)
        # Money / Money => ratio
        (@rep.to_f) / (x.Money_rep(@currency).to_f)
      else
        # Money / Number => Money
        new_rep(@rep / x)
      end
    end

    def format(*opt)
      @currency.format(self, *opt)
    end

    # Coercions
    def to_s(*opt)
      @currency.format(self, *opt)
    end

    def to_f
      Float(@rep) / @currency.scale
    end

    def to_i
      @rep / @currency.scale
    end

    def zero?
      @rep == 0
    end

    def positive?
      @rep > 0
    end
    
    def negative?
      @rep < 0
    end

    # Implicit currency conversions?
    def Money_rep(currency)
      # Attempt conversion?
      if @currency != currency
	self.convert(currency).rep
        # raise("Incompatible Currency: #{@currency} != #{currency}")
      else
        @rep
      end
    end

    def inspect(*opts)
      self.format(:with_symbol, :with_currency).inspect
    end

    # How to alias a method defined in an object superclass in a different class:
    define_method(:inspect_deep, Object.instance_method(:inspect))
    # How call a method defined in a superclass from a method with a different name:
    #def inspect_deep(*opts)
    #  self.class.superclass.instance_method(:inspect).bind(self).call 
    #end
  end

  # END MODULE
end
