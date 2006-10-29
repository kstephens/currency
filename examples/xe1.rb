$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'currency'
require 'currency/currency_exchange_xe'

ex = Currency::CurrencyExchangeXe.new()

puts ex.inspect
puts ex.parse_page_rates.inspect

usd = Currency::Money.new("1", 'USD')

puts "usd = #{usd}"

cad = usd.convert(:CAD)
puts "cad = #{cad}"



