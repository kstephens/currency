module Currency
module Exchange

    @@default = nil
    def self.default 
      @@default ||= Base.new
    end
    def self.default=(x)
      @@default = x
    end

    @@current = nil
    def self.current
      @@current || self.default || (raise UndefinedExchange, "Currency::Exchange.current not defined")
    end
    def self.current=(x)
      @@current = x
    end

end
end

require 'currency/exchange/base'
require 'currency/exchange/rate'
