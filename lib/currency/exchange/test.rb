module Currency
module Exchange

  # This can convert only between USD and CAD
  class Test < Base
    @@instance = nil
    def self.instance(*opts)
      @@instance ||= self.new(*opts)
    end

    # Sample constant.
    def self.USD_CAD; 1.1708; end

    def load_exchange_rate(c1, c2)
      # $stderr.puts "load_exchange_rate(#{c1}, #{c2})"
      rate = 0.0
      if ( c1.code == :USD && c2.code == :CAD )
        rate = self.class.USD_CAD
      end
      rate > 0 ? Rate.new(c1, c2, rate, self.class.name) : nil
    end
  end

end # module
end # module

# Install as current
Currency::Exchange.default = Currency::Exchange::Test.instance

