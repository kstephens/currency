
#require File.dirname(__FILE__) + '/../test_helper'

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
    assert_kind_of Money, m = Money.new("1234567.89")
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

end

end # module

