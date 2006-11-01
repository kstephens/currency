module Currency
  module Exception
  end
end
  
# Base class for all Currency::Exception.
class Currency::Exception::Base < Exception
end

module Currency
  module Exception
    # Error during string parsing.
    class InvalidMoneyString < Base
    end
  
    # Error in Currency code formeat.
    class InvalidCurrencyCode < Base
    end
    
    # Error during conversion between currencies.
    class IncompatibleCurrency < Base
    end

    # Error if an Exchange is not defined.
    class UndefinedExchange < Base
    end

    # Error if a Currency is unknown.
    class UnknownCurrency < Base
    end

    # Error if an Exchange cannot provide an Exchange::Rate.
    class UnknownRate < Base
    end

    # Error if an Exchange::Rate is not valid.
    class InvalidRate < Base
    end

  end
end
