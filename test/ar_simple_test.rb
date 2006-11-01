require 'test/ar_test_base'
require 'currency'

require 'rubygems'
require 'active_record'
require 'active_record/migration'
require 'currency/active_record'

module Currency

class ArSimpleTest < ArTestBase

  def test_simple
    insert_records

    assert_not_nil usd = @currency_test.find(@usd.id)
    assert_same_currency usd, @usd

    assert_not_nil cad = @currency_test.find(@cad.id)
    assert_equal_money cad, @cad

    assert_equal   cad.amount.currency.code, :USD

    delete_records
  end

end

end # module

