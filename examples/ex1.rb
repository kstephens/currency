require File.join(File.dirname(__FILE__), '..', 'lib', 'currency')

x = Currency::Money.new("1,203.43", 'USD')

puts x.to_s
puts (x * 10).to_s
puts (x * 33333).to_s

puts x.currency.code.inspect

