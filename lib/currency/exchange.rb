# -*- ruby -*-
#
# = Currency::Exchange
#
# The Currency::Exchange package is responsible for
# the buying and selling of currencies.
#
# This feature is currently unimplemented.
#

module Currency
module Exchange
    @@default = nil
    @@current = nil

    # Returns the default Currency::Exchange object.
    #
    # If one is not specfied an instance of Currency::Exchange::Base is
    # created.  Currency::Exchange::Base cannot service any
    # conversion rate requests.
    def self.default 
      @@default ||= raise("UNIMPLEMENTED")
    end

    # Sets the default Currency::Exchange object.
    def self.default=(x)
      @@default = x
    end

    # Returns the current Currency::Exchange object used during
    # explicit and implicit Money conversions.
    # 
    # If #current= has not been called and #default= has not been called,
    # then UndefinedExchange is raised.
    def self.current
      @@current || self.default || (raise Exception::UndefinedExchange.new("Currency::Exchange.current not defined"))
    end

    # Sets the current Currency::Exchange object used during
    # explicit and implicit Money conversions.
    def self.current=(x)
      @@current = x
    end
end
end

require 'currency/exchange/rate'
require 'currency/exchange/rate/source'
