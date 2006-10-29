$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'currency'
require 'currency/exchange/xe'

ex = Currency::Exchange::Xe.new()

puts ex.inspect
puts ex.parse_page_rates.inspect

usd = Currency::Money.new("1", 'USD')

puts "usd = #{usd}"

cad = usd.convert(:CAD)
puts "cad = #{cad}"



