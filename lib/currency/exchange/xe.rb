# Connects to http://xe.com and parses "XE.com Quick Cross Rates"
# from home page HTML.
#
# This is for demonstration purposes.
#

require 'net/http'
require 'open-uri'

module Currency
module Exchange

  class Xe < Base
    @@instance = nil
    # Returns a singleton instance.
    def self.instance(*opts)
      @@instance ||= self.new(*opts)
    end


    # Defaults to "http://xe.com/"
    attr_accessor :uri


    # Defines the number of seconds rates until rates
    # become invalid, causing a request of new rates.
    #
    # Defaults to 600 seconds.
    attr_accessor :time_to_live


    # Defines the number of random seconds to add before
    # rates become invalid.
    #
    # Defaults to 30 seconds.
    attr_accessor :time_to_live_fudge


    # Defines the pivot currency for http://xe.com/.
    PIVOT_CURRENCY = :USD


    # This Exchange's name is the same as its #uri.
    def name
      uri
    end


    def initialize(*opt)
      self.pivot_currency = PIVOT_CURRENCY
      self.uri = 'http://xe.com/'
      self.time_to_live = 600
      self.time_to_live_fudge = 30
      @xe_rates = nil
      @processing_rates = false
      super(*opt)
    end


    def clear_rates
      @xe_rates && @xe_rates.clear
      super
    end


    # Returns true if the cache of xe.com rates
    # is expired.
    def expired?
      if @time_to_live &&
         @xe_rates_renew_time &&
         (Time.now > @xe_rates_renew_time)

        if @xe_rates 
          $stderr.puts "#{self}: rates expired on #{@xe_rates_renew_time}" if @verbose
          
          @old_rates ||= @xe_rates
         
          @xe_rates = nil
        end

        true
      else
        false
      end
    end


    # Check expired? before returning a Rate.
    def rate(c1, c2, time)
      if expired?
        clear_rates
      end
      super(c1, c2, time)
    end


    # Returns a cached Hash of rates:
    #
    #    xe.xe_rates[:USD][:CAD] => 1.0134
    #
    def xe_rates
      old_rates = nil
      # Check expiration.
      expired?

      # Return rates, if cached.
      return @xe_rates if @xe_rates

      # Force load of rates
      @xe_rates = xe_rates_load

      # Flush old rates.
      @old_rates = nil

      # Update expiration.
      if time_to_live
        @xe_rates_renew_time = @rate_timestamp + (time_to_live + (time_to_live_fudge || 0))
        $stderr.puts "#{self}: rates expire on #{@xe_rates_renew_time}" if @verbose
      end
      
      @xe_rates
    end


    def xe_rates_load
      # Do not allow re-entrancy
      raise "Reentrant!" if @processing_rates

      # Begin processing new rate request.
      @processing_rates = true

      # Clear cached Rates.
      clear_rates

      # Parse rates from HTML page.
      rates = parse_page_rates
      
      unless rates 
        # FIXME: raise Exception::???
        return rates 
      end

      # Compute new rate timeps
      @rate_timestamp = Time.now # TODO: Extract this from HTML page!

      # End processsing new rate request.
      @processing_rates = false

      rates
    end


    # Returns the URI content.
    def get_page
      data = open(uri) { |data| data.read }
      
      data = data.split(/[\r\n]/)

      data
    end


    # Parses http://xe.com homepage HTML for
    # quick rates of 10 currencies.
    def parse_page_rates(data = nil)
      data = get_page unless data
      
      # Chomp after
      until data.empty?
        line = data.pop
        break if line =~ /Need More currencies\?/
      end

      # Chomp before
      until data.empty?
        line = data.shift
        break if line =~ /XE.com Quick Cross Rates/
      end

      until data.empty?
        line = data.shift
        break if line =~ /Confused about how to use the rates/i
      end

      until data.empty?
        line = data.shift
        break if line =~ /^\s*<\/tr>/i
      end
      # $stderr.puts "#{data[0..4].inspect}"

      # Read first table row to get position for each currency
      currency = [ ]
      until data.empty?
        line = data.shift
        break if line =~ /^\s*<\/tr>/i
        if md = /<td><IMG .+ ALT="([A-Z][A-Z][A-Z])"/i.match(line) #"
          cur = md[1].intern
          cur_i = currency.size
          currency.push(cur)
          # $stderr.puts "Found currency header: #{cur.inspect} at #{cur_i}"
        end
      end

      # $stderr.puts "#{data[0..4].inspect}"
      
      # Skip blank <tr>
      until data.empty?
        line = data.shift
        break if line =~ /^\s*<td>.+1.+USD.+=/
      end

      until data.empty?
        line = data.shift
        break if line =~ /^\s*<\/tr>/i
      end

      # $stderr.puts "#{data[0..4].inspect}"

      # Read first row of 1 USD = ...
      
      rate = { }
      cur_i = -1
      until data.empty?
        line = data.shift
        break if cur_i < 0 && line =~ /^\s*<\/tr>/i  
        if md = /<td>\s+(\d+\.\d+)\s+<\/td>/.match(line)
          usd_to_cur = md[1].to_f
          cur_i = cur_i + 1
          cur = currency[cur_i]
          (rate[PIVOT_CURRENCY] ||= {})[cur] = usd_to_cur
        end
      end

      rate
    end

    # Loads cached rates from xe.com and creates Rate objects
    # for 10 currencies.
    def get_rate_base(c1, c2, time)
      # $stderr.puts "get_rate(#{c1}, #{c2}, #{time.inspect})"
      raise Exception::UnknownRate.new("#{self}: cannot get historical rates") if time

      rates = xe_rates # Load rates
      rates_pivot = rates[PIVOT_CURRENCY]
      raise Exception::UnknownRate.new("#{self}: cannot get base currency #{PIVOT_CURRENCY.inspect}") unless rates_pivot

      rate = 0.0
      r1 = nil
      r2 = nil

      # Use USD as pivot to convert between c1 and c2.
      if ( c1.code == PIVOT_CURRENCY && (r2 = rates_pivot[c2.code]) )
        rate = r2
      end

      # $stderr.puts "XE Rate: #{c1.code} / #{c2.code} = #{rate}"

      rate > 0 ? new_rate(c1, c2, rate, @rate_timestamp) : nil
    end


    # Return a list of base rates.
    def get_rates(time)
      # $stderr.puts "get_rates(#{time})"
      raise Exception::UnknownRate.new("#{self}: cannot get historical rates") if time
      result = [ ]

      rates = xe_rates # Load rates
      rates_pivot = rates[PIVOT_CURRENCY]
      raise Exception::UnknownRate.new("#{self}: cannot get base rate #{PIVOT_CURRENCY.inspect}") unless rates_pivot

      rates_pivot.keys.each do | c2 |
        result << get_rate(c1, c2, time)
      end

      result
    end


  end # class

end # module
end # module


# Install as default.
Currency::Exchange.default = Currency::Exchange::Xe.instance

