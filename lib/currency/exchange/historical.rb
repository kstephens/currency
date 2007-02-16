
module Currency
module Exchange
  # Gets historical rates from database using Active::Record.
  # Rates are retrieved using Currency::Exchange::Historical::Rate as
  # a database proxy.
  #
  # See Currency::Exchange::Historical::Writer for a rate archiver.
  #
  class Historical < ::Currency::Exchange::Base

    # Select specific rate source.
    # Defaults to nil
    attr_accessor :source

    def initialize
      @source = nil # any
      super
    end


    def source_key
      @source ? @source.join(',') : ''
    end


    # This Exchange's name is the same as its #uri.
    def name
      "historical #{source.inspect}"
    end


    def initialize(*opt)
      super
      @rates_cache = { }
      @raw_rates_cache = { }
    end


    def clear_rates
      @rates_cache.clear
      @raw_rates_cache.clear
      super
    end


    # Returns a Rate.
    def get_rate(c1, c2, time)
      get_rates(time).select{ | r | r.c1 == c1 && r.c2 == c2 }[0]
    end


    # Return a list of base Rates.
    def get_rates(time = nil)
      @rates_cache["#{source_key}:#{time}"] ||= 
        get_raw_rates(time).collect do | rr |
          rr.to_rate
        end
    end


    # Return a list of raw rates.
    def get_raw_rates(time = nil)
      @raw_rates_cache["#{source_key}:#{time}"] ||= 
        ::Currency::Exchange::Historical::Rate.new(:c1 => nil, :c2 => nil, :date => time, :source => source).
          find_matching_this(:all)
    end

  end # class

end # module
end # module


require 'currency/exchange/historical/rate'

# Install as default.
# Currency::Exchange.default = Currency::Exchange::Xe.instance

