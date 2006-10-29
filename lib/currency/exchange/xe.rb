require 'net/http'
require 'open-uri'

module Currency
  # Represents connects to http://xe.com and groks "XE.com Quick Cross Rates"

  class CurrencyExchangeXe < CurrencyExchange
    @@instance = nil
    def self.instance(*opts)
      @@instance ||= self.new(*opts)
    end

    attr_accessor :uri

    def initialize(*opt)
      super(*opt)
      self.uri = 'http://xe.com/'
      @rates = nil
    end

    def rates
      return @rates if @rates

      @rates = parse_page_rates
      return @rates unless @rates

      @rates_usd_cur = @rates[:USD]
      @rate_timestamp = Time.now
      
      @rates
    end

    def get_page
      data = open(uri) { |data| data.read }
      
      data = data.split(/[\r\n]/)

      data
    end

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
          (rate[:USD] ||= {})[cur] = usd_to_cur
        end
      end

      rate
    end

    def load_exchange_rate(c1, c2)
      rates # Load rates

      # $stderr.puts "load_exchange_rate(#{c1}, #{c2})"
      rate = 0.0
      r1 = nil
      r2 = nil

      if ( c1.code == :USD && (r2 = @rates_usd_cur[c2.code]) )
        rate = r2
      elsif ( c2.code == :USD && (r1 = @rates_usd_cur[c2.code]) )
        rate = 1.0 / r1
      elsif ( (r1 = @rates_usd_cur[c1.code]) && (r2 = @rates_usd_cur[c2.code]) )
        rate = r2 / r1
      end

      # $stderr.puts "XE Rate: #{c1.code} / #{c2.code} = #{rate}"

      rate > 0 ? ExchangeRate.new(c1, c2, rate, self.class.name, @rate_timestamp) : nil
    end
  end

  # END MODULE
end

# Install as current
Currency::CurrencyExchange.default = Currency::CurrencyExchangeXe.instance

