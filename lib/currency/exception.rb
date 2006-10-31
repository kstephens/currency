module Currency
  class Error < Exception; end

  class InvalidMoneyString < Error
  end
  
  class InvalidCurrencyCode < Error
  end
  
  class IncompatibleCurrency < Error
  end

  class UndefinedExchange < Error
  end
end
