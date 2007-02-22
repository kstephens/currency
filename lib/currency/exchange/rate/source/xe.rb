# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

require 'currency/exchange/rate/source/base'

require 'net/http'
require 'open-uri'

# Connects to http://xe.com and parses "XE.com Quick Cross Rates"
# from home page HTML.
#
# This is for demonstration purposes.
#
class Currency::Exchange::Rate::Source::Xe < ::Currency::Exchange::Rate::Source::Provider
  # Defines the pivot currency for http://xe.com/.
  PIVOT_CURRENCY = :USD
  
  def initialize(*opt)
    self.uri = 'http://xe.com/'
    self.pivot_currency = PIVOT_CURRENCY
    @raw_rates = nil
    super(*opt)
  end
  

  # Returns 'xe.com'.
  def name
    'xe.com'
  end


  def clear_rates
    @raw_rates = nil
    super
  end
  

  # Returns a cached Hash of rates:
  #
  #    xe.xe_rates[:USD][:CAD] => 1.0134
  #
  def raw_rates
    # Force load of rates
    @raw_rates ||= parse_page_rates
  end
  
  

  # Parses http://xe.com homepage HTML for
  # quick rates of 10 currencies.
  def parse_page_rates(data = nil)
    data = get_page_content unless data

    data = data.split(/[\r\n]/)
    
    @rate_timestamp = nil

    # Chomp after
    until data.empty?
      line = data.pop
      break if line =~ /Need More currencies\?/
    end
    
    # Chomp before Quick Cross Rates
    until data.empty?
      line = data.shift
      break if line =~ /XE.com Quick Cross Rates/
    end

    # Look for date.
    md = nil
    until data.empty?
      line = data.shift
      break if md = /rates as of (\d\d\d\d)\.(\d\d)\.(\d\d)\s+(\d\d):(\d\d).*GMT/.match(line)
    end
    if md
      yyyy, mm, dd, h, m = md[1].to_i, md[2].to_i, md[3].to_i, md[4].to_i, md[5].to_i
      @rate_timestamp = Time.gm(yyyy, mm, dd, h, m, 0, 0) rescue nil
      #$stderr.puts "parsed #{md[0].inspect} => #{yyyy}, #{mm}, #{dd}, #{h}, #{m}"
      #$stderr.puts "  => #{@rate_timestamp && @rate_timestamp.xmlschema}"
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
        next unless cur
        next if cur.to_s == PIVOT_CURRENCY.to_s
        (rate[PIVOT_CURRENCY] ||= {})[cur] = usd_to_cur
        (rate[cur] ||= { })[PIVOT_CURRENCY] ||= 1.0 / usd_to_cur
        $stderr.puts "#{cur.inspect} => #{usd_to_cur}" if @verbose
      end
    end
    
    rate
  end
  
  
  # Return a list of known base rates.
  def load_rates(time = nil)
    if time
      $stderr.puts "#{self}: WARNING CANNOT SUPPLY HISTORICAL RATES" unless @time_warning
      @time_warning = true
    end

    rates = raw_rates # Load rates
    rates_pivot = rates[PIVOT_CURRENCY]
    raise ::Currency::Exception::UnknownRate.new("#{self}: cannot get base rate #{PIVOT_CURRENCY.inspect}") unless rates_pivot
    
    result = rates_pivot.keys.collect do | c2 | 
      new_rate(PIVOT_CURRENCY, c2, rates_pivot[c2], @rate_timestamp)
    end
    
    result
  end
  
 
end # class


