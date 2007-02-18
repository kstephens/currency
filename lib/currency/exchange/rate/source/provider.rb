# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

require 'currency/exchange/rate/source'


# Base class for rate data providers.
# Assumes that rate sources provide more than one rate per query.
class Currency::Exchange::Rate::Source::Provider < Currency::Exchange::Rate::Source::Base
  # The URI used to access the rate source.
  attr_accessor :uri
  
  # The Time used to query the rate source.

  attr_accessor :date
  # The name is the same as its #uri.
  alias :name :uri 
  

  # Returns the date to query for rates.
  # Defaults to yesterday.
  def date
    @date ||= Time.now - 24 * 60 * 60 # yesterday.
  end


  # Returns year of query date.
  def date_YYYY
    '%04d' % date.year
  end


  # Return month of query date.
  def date_MM
    '%02d' % date.month
  end


  # Returns day of query date.
  def date_DD
    '%02d' % date.day
  end


  # Returns the URI string as evaluated with this object.
  def get_uri
    uri = self.uri
    uri = "\"#{uri}\""
    uri = instance_eval(uri)
  end


  # Returns the URI content.
  def get_page_content
    data = open(get_uri) { |data| data.read }
    
    data
  end


  # Clear cached rates from this source.
  def clear_rates
    @rates = nil
    super
  end


  # Returns current base Rates or calls load_rates to load them from the source.
  def rates(time = nil)
    @rates ||= load_rates
  end
  

  # Returns an array of base Rates from the rate source.
  #
  # Subclasses must define this method.
  def load_rates
    raise('Subclass responsiblity')
  end


  # Return a matching base rate?
  def get_rate(c1, c2, time)
    matching_rates = rates.select do | rate |
      rate.c1 == c1 &&
      rate.c2 == c2 &&
      (! time || normalize_time(rate.date) == time)
    end
    matching_rates[0]
  end

  alias :get_rate_base :get_rate

end # class



