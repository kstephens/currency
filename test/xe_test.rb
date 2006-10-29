# REAL
#require File.dirname(__FILE__) + '/../test_helper'

require 'test/test_base'
require 'currency' # For :type => :money
require 'currency/currency_exchange_xe'

module Currency

class XeTest < TestBase
  def setup
    super
    # Force XE Exchange.
    CurrencyExchange.default = CurrencyExchangeXe.instance
  end

  def test_xe_usd_cad
    assert_not_nil rates = CurrencyExchange.default.rates
    assert_not_nil rates[:USD]
    assert_not_nil usd_cad = rates[:USD][:CAD]

    assert_not_nil usd = Money.new(123.45, :USD)
    assert_not_nil cad = usd.convert(:CAD)

    assert_kind_of Numeric, m = (cad.rep.to_f / usd.rep.to_f)
    # $stderr.puts "m = #{m}"
    assert_equal_float usd_cad, m, 0.001
  end

end

end # module

