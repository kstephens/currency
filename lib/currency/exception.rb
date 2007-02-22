# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

module Currency::Exception
    # Base class for all Currency::Exception objects.
    class Base < ::Exception
    end

    # Error during string parsing.
    class InvalidMoneyString < Base
    end

    # Error during coercion of external Money values.
    class InvalidMoneyValue < Base
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

    # Error if an Exchange Rate Source cannot provide an Exchange::Rate.
    class UnknownRate < Base
    end

    # Error if an Exchange::Rate is not valid.
    class InvalidRate < Base
    end
    
    # Error if a subclass is responsible for implementing a method.
    class SubclassResponsibility < Base
    end
  
end # module
