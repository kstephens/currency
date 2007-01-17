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


    # Install as default.
    def self.make_default
      ::Currency::Exchange.default = ::Currency::Exchange::Test.instance
    end


    def initialize(*opts)
      super(*opts)
      self.name = self.class.name
    end


    # Test rate from :USD to :CAD.
    def self.USD_CAD; 1.1708; end


    # Test rate from :USD to :EUR.
    def self.USD_EUR; 0.7737; end


    # Test rate from :USD to :EUR.
    def self.USD_GBP; 0.5098; end


    # Returns test Rate for USD to [ CAD, EUR, GBP ]. 
    def get_rate_base(c1, c2, time)
      # $stderr.puts "get_rate_base(#{c1}, #{c2}, #{time})"
      rate = 0.0

      if    c1.code == :USD && c2.code == :CAD
        rate = self.class.USD_CAD
      elsif c1.code == :USD && c2.code == :EUR
        rate = self.class.USD_EUR
      elsif c1.code == :USD && c2.code == :GBP
        rate = self.class.USD_GBP
      end

      rate > 0 ? new_rate(c1, c2, rate, time) : nil
    end

  end # class

end # module
end # module

# Install as default.
Currency::Exchange::Test.make_default

