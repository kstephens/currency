# -*- ruby -*-
#
# = Currency
#
# The Currency package provides an object-oriented model of:
#
# * currencies 
# * exchanges
# * exchange rates
# * monetary values
#
# The core classes are:
#
# * Currency::Money - uses a scaled integer representation of a monetary value and performs accurate conversions to and from string values.
# * Currency::Currency - provides an object-oriented representation of a currency.
# * Currency::Exchange::Base - the base class for a currency exchange rate provider.
# * Currency::Exchange::Rate - represents a exchange rate between two currencies.
#
# 
# The example below uses Currency::Exchange::Xe to automatically get 
# exchange rates from http://xe.com/ :
#
#    require 'currency'
#    require 'currency/exchange/xe'
#    
#    usd = Currency::Money('6.78', :USD)
#    puts "usd = #{usd.format}"
#    cad = usd.convert(:CAD)
#    puts "cad = #{cad.format}"
#
# == ActiveRecord Suppport
#
# This package also contains ActiveRecord support for money values:
#
#    require 'currency'
#    require 'currency/active_record'
#    
#    class Entry < ActiveRecord::Base
#       money :amount
#    end
# 
# In the example above, the entries.amount database column is an INTEGER that represents US cents. 
# The currency code of the money value can be stored in an additional database column or a default currency can be used.
#
# == Future Enhancements
#
# * storage and retrival of historical exchange rates
# * exchange rate polling for population of historical rates
# * support for inflationary rates within a currency, e.g. $10 USD in the year 1955 in 2006 USD.
# 
# == SVN Repo
#
#    svn checkout svn://rubyforge.org/var/svn/currency/currency/trunk
#
# == Examples
#
# See the examples/ and test/ directorys
#
# == Author
#
# Kurt Stephens http://kurtstephens.com
#
# == Support
#
# ruby-currency(at)umleta.com
#

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'currency/exception'
require 'currency/money'
require 'currency/currency_factory'
require 'currency/currency'
require 'currency/money'
require 'currency/exchange'
require 'currency/core_extensions'

