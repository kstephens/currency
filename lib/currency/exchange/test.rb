# This class is a test Exchange.
# It can convert only between USD and CAD.

module Currency
module Exchange

  class Test < Base
    @@instance = nil

    # Returns a singleton instance.
    def self.instance(*opts)
      @@instance ||= self.new(*opts)
    end

    def initialize(*opts)
      super(*opts)
    end

    # Test rate from :USD to :CAD.
    def self.USD_CAD; 1.1708; end

    # Returns test Rate for USD and CAD pairs. 
    def get_rate(c1, c2)
      # $stderr.puts "load_exchange_rate(#{c1}, #{c2})"
      rate = 0.0
      if ( c1.code == :USD && c2.code == :CAD )
        rate = self.class.USD_CAD
      end
      rate > 0 ? Rate.new(c1, c2, rate, self) : nil
    end

  end # class

end # module
end # module

# Install as default.
Currency::Exchange.default = Currency::Exchange::Test.instance

