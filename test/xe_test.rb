# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

require 'test/test_base'

require 'currency' # For :type => :money
require 'currency/exchange/rate/source/xe'

module Currency

class XeTest < TestBase
  def setup
    super
  end


  def get_rate_source
    source = Exchange::Rate::Source::Xe.new
    # source.verbose = true
    deriver = Exchange::Rate::Deriver.new(:source => source)
    deriver
  end


  def test_xe_usd_cad
    assert_not_nil rates = Exchange::Rate::Source.default.source.raw_rates
    assert_not_nil rates[:USD]
    assert_not_nil usd_cad = rates[:USD][:CAD]

    assert_not_nil usd = Money.new(123.45, :USD)
    assert_not_nil cad = usd.convert(:CAD)

    assert_kind_of Numeric, m = (cad.to_f / usd.to_f)
    # $stderr.puts "m = #{m}"
    assert_equal_float usd_cad, m, 0.001
  end


  def test_xe_cad_eur
    assert_not_nil rates = Exchange::Rate::Source.default.source.raw_rates
    assert_not_nil rates[:USD]
    assert_not_nil usd_cad = rates[:USD][:CAD]
    assert_not_nil usd_eur = rates[:USD][:EUR]

    assert_not_nil cad = Money.new(123.45, :CAD)
    assert_not_nil eur = cad.convert(:EUR)

    assert_kind_of Numeric, m = (eur.to_f / cad.to_f)
    # $stderr.puts "m = #{m}"
    assert_equal_float((1.0 / usd_cad) * usd_eur, m, 0.001)
  end

  def test_xe_gbp_usd
    assert_not_nil gbp = Money.new(123.45, :GBP)
    assert_not_nil usd = gbp.convert(:USD)

    assert_kind_of Numeric, m = (usd.to_f / gbp.to_f)
    # $stderr.puts "gbp = #{gbp}, usd = #{usd}, m = #{m}"
  end

end

end # module

