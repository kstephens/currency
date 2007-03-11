# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

require 'currency/exchange/rate/source/base'

require 'net/http'
require 'open-uri'
# Cant use REXML because of missing </form> tags -- 2007/03/11
# require 'rexml/document'

# Connects to http://xe.com and parses "XE.com Quick Cross Rates"
# from home page HTML.
#
# This is for demonstration purposes.
#
class Currency::Exchange::Rate::Source::Xe < ::Currency::Exchange::Rate::Source::Provider
  class ParserError < ::Currency::Exception::Base; end

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
  #    xe.raw_rates[:USD][:CAD] => 1.0134
  #
  def raw_rates
    # Force load of rates
    @raw_rates ||= parse_page_rates
  end
  
  

  # Parses http://xe.com homepage HTML for
  # quick rates of 10 currencies.
  def parse_page_rates(data = nil)
    data = get_page_content unless data

    @lines = data = data.split(/\n/);

    @rate_timestamp = nil

    eat_lines_until /More currencies\.\.\.<\/a>/i
    eat_lines_until /^\s*<tr>/i
    eat_lines_until /^\s*<tr>/i
    
    # Read first table row to get position for each currency
    currency = [ ]
    eat_lines_until /^\s*<\/tr>/i do 
      if md = /<td[^>]+?>.*?\/> ([A-Z][A-Z][A-Z])<\/td>/.match(@line)
        cur = md[1].intern
        cur_i = currency.size
        currency.push(cur)
        $stderr.puts "Found currency header: #{cur.inspect} at #{cur_i}" if @verbose
      end
    end
    raise ParseError, "Currencies header not found" if currency.empty?
    

    # Skip until "1 USD ="
    eat_lines_until /^\s*<td[^>]+?> 1&nbsp;+USD&nbsp;=/
     
    # Read first row of 1 USD = ...
    rate = { }
    cur_i = -1 
    eat_lines_until /^\s*<\/tr>/i do 
      if md = /<td[^>]+?>\s*?(\d+\.\d+)\s*?<\/td>/i.match(@line)
        usd_to_cur = md[1].to_f
        cur_i = cur_i + 1
        cur = currency[cur_i]
        raise ParseError, "Currency not found at column #{cur_i}" unless cur
        next if cur.to_s == PIVOT_CURRENCY.to_s
        (rate[PIVOT_CURRENCY] ||= {})[cur] = usd_to_cur
        (rate[cur] ||= { })[PIVOT_CURRENCY] ||= 1.0 / usd_to_cur
        $stderr.puts "#{cur.inspect} => #{usd_to_cur}" if @verbose
      end
    end
    raise ParseError, "Currency rates not found" if rate.keys.empty?
    raise ParseError, "Not all rates found" if rate.keys.size != currency.size
    
    @lines = @line = nil

    rate
  end


  def eat_lines_until(rx)
    until @lines.empty?
      @line = @lines.shift
      if md = rx.match(@line)
        $stderr.puts "\nMATCHED #{@line.inspect} WITH #{rx.inspect} AT LINES:\n#{@lines[0..4].inspect}" if @verbose
        return md
      end
      yield @line if block_given?
    end
    raise ParseError, rx.inspect
    false
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


