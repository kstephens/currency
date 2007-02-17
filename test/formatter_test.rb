# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

require 'test/test_base'
require 'currency'

module Currency

class FormatterTest < TestBase
  def setup
    super
  end

  ############################################
  # Simple stuff.
  #

  def test_default
    assert_kind_of Money, m = ::Currency::Money("1234567.89")
    assert_equal m.currency, Currency.default
    assert_equal m.currency.code, :USD
    assert_equal "$1,234,567.89", m.to_s

    m
  end


  def test_thousands
    m = test_default
    assert_equal "$1234567.89", m.to_s(:thousands => false)
    assert_equal "$1,234,567.89", m.to_s(:thousands => true)

    m
  end


  def test_cents
    m = test_default
    assert_equal "$1,234,567", m.to_s(:cents => false)
    assert_equal "$1,234,567.89", m.to_s(:cents => true)

    m
  end


  def test_symbol
    m = test_default
    assert_equal "1,234,567.89", m.to_s(:symbol => false)
    assert_equal "$1,234,567.89", m.to_s(:symbol => true)

    m
  end


  def test_code
    m = test_default
    assert_equal "$1,234,567.89", m.to_s(:code => false)
    assert_equal "$1,234,567.89 USD", m.to_s(:code => true)

    m
  end

  def test_misc
    m = ::Currency::Money(12.45, :USD)
    assert_equal "$12.45 <span class=\"currency_code\">USD</span>", 
    m.to_s(:html => true, :code => true)

    m = ::Currency::Money(12.45, :EUR)
    assert_equal "&#8364;12.45 <span class=\"currency_code\">EUR</span>", 
    m.to_s(:html => true, :code => true)

    m = ::Currency::Money(12.45, :EUR)
    assert_equal "&#8364;12.45 <span class=\"currency_code\">EUR</span>", 
    m.to_s(:html => true, :code => true, :thousands_separator => '_')
  end


  def test_round_trip
    assert_not_nil m = ::Currency::Money("1234567.89", :USD)
    assert_not_nil m2 = ::Currency::Money(m.inspect)
    assert_equal m.rep, m2.rep
    assert_equal m.currency, m2.currency
    assert_nil   m2.time
    assert_equal m.inspect, m2.inspect
  end

end

end # module

