module Currency
module Exchange

    @@default = nil
    def self.default 
      @@default ||= self.new
    end
    def self.default=(x)
      @@default = x
    end

end
end

require 'currency/exchange/base'
require 'currency/exchange/rate'
