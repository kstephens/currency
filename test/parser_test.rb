# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

require 'test/test_base'
require 'currency'

module Currency

class ParserTest < TestBase
  def setup
    super
    @parser = ::Currency::Currency.USD.parser_or_default
  end

  ############################################
  # Simple stuff.
  #

  def test_default
    
  end


  def test_thousands
    assert_equal 123456789, @parser.parse("1234567.89").rep
    assert_equal 123456789, @parser.parse("1,234,567.89").rep
  end


  def test_cents
    assert_equal  123456789, @parser.parse("1234567.89").rep
    assert_equal  123456700, @parser.parse("1234567").rep
    assert_equal -123456700, @parser.parse("-1234567").rep
    assert_equal  123456700, @parser.parse("+1234567").rep

  end



  def test_round_trip
    ::Currency::Currency.default = :USD
    assert_not_nil m = ::Currency::Money("1234567.89", :CAD)
    assert_not_nil m2 = ::Currency::Money(m.inspect)
    assert_equal m.rep, m2.rep
    assert_equal m.currency, m2.currency
    assert_nil   m2.time
    assert_equal m.inspect, m2.inspect
  end

end

end # module

