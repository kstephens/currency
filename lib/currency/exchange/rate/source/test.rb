# This class is a test Rate Source.
# It can convert only between USD and CAD.

require 'currency/exchange/rate/source/test'

module Currency
module Exchange
class Rate
module Source

  class Test < Provider
    @@instance = nil

    # Returns a singleton instance.
    def self.instance(*opts)
      @@instance ||= self.new(*opts)
    end


    def initialize(*opts)
     self.uri = 'none://localhost/Test'
     super(*opts)
    end


    def name
      'Test'
    end

    # Test rate from :USD to :CAD.
    def self.USD_CAD; 1.1708; end


    # Test rate from :USD to :EUR.
    def self.USD_EUR; 0.7737; end


    # Test rate from :USD to :EUR.
    def self.USD_GBP; 0.5098; end


    # Returns test Rate for USD to [ CAD, EUR, GBP ]. 
    def rates
      [ new_rate(:USD, :CAD, self.class.USD_CAD),
        new_rate(:USD, :EUR, self.class.USD_EUR),
        new_rate(:USD, :GBP, self.class.USD_GBP) ]
    end

  end # class

end # module
end # class
end # module
end # module

