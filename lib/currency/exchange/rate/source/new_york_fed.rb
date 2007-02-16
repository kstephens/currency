
require 'currency/exchange/rate/source/base'

require 'net/http'
require 'open-uri'
require 'rexml/document'


# Connects to http://www.newyorkfed.org/markets/fxrates/FXtoXML.cfm
# ?FEXdate=2007%2D02%2D14%2000%3A00%3A00%2E0&FEXtime=1200 and parses XML.
#
# This is for demonstration purposes.
#
class Currency::Exchange::Rate::Source::NewYorkFed < ::Currency::Exchange::Rate::Source::Provider
  # Defines the pivot currency for http://xe.com/.
  PIVOT_CURRENCY = :USD
  
  def initialize(*opt)
    self.uri = 'http://www.newyorkfed.org/markets/fxrates/FXtoXML.cfm?FEXdate=#{date_YYYY}%2D#{date_MM}%2D#{date_DD}%2000%3A00%3A00%2E0&FEXtime=1200'
    @xe_rates = nil
    super(*opt)
  end
  

  def name
    'newyorkfed.org'
  end


  def clear_rates
    @fed_rates = nil
    super
  end
  

  def get_content
    data = open(get_uri) { |data| data.read }
    
    data
  end


  def raw_rates
    rates
    @raw_rates
  end


  # Parses XML for rates.
  def parse_rates(data = nil)
    data = get_content unless data
    
    rates = [ ]

    @raw_rates = { }

    doc = REXML::Document.new(data).root
    doc.elements.to_a('//frbny:Series').each do | series |
      c1 = series.attributes['UNIT'] # WHAT TO DO WITH @UNIT_MULT?
      c1 = c1.upcase.intern

      c2 = series.elements.to_a('frbny:Key/frbny:CURR')[0].text
      c2 = c2.upcase.intern
      
      rate = series.elements.to_a('frbny:Obs/frbny:OBS_VALUE')[0].text.to_f

      date = series.elements.to_a('frbny:Obs/frbny:TIME_PERIOD')[0].text
      date = Time.parse("#{date} 12:00:00 -05:00") # USA NY => EST

      rates << new_rate(c1, c2, rate, date)

      (@raw_rates[c1] ||= { })[c2] ||= rate
      (@raw_rates[c2] ||= { })[c1] ||= 1.0 / rate

    end

    rates
  end
  
  
  # Return a list of known base rates.
  def load_rates   
    parse_rates
  end
  
 
end # class



