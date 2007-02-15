require 'test/test_base'

require 'currency' # For :type => :money
require 'currency/exchange/rate/source/new_york_fed'

module Currency

class NewYorkFedTest < TestBase
  def setup
    super
    # Force XE Exchange.
    source = Exchange::Rate::Source::NewYorkFed.new
    deriver = Exchange::Rate::Deriver.new(:source => source)
    Exchange.default = deriver
  end


  def test_usd_cad
    assert_not_nil rates = Exchange.default.source.raw_rates
    assert_not_nil rates[:USD]
    assert_not_nil usd_cad = rates[:USD][:CAD]

    assert_not_nil usd = Money.new(123.45, :USD)
    assert_not_nil cad = usd.convert(:CAD)

    assert_kind_of Numeric, m = (cad.to_f / usd.to_f)
    # $stderr.puts "m = #{m}"
    assert_equal_float usd_cad, m, 0.001
  end


  def test_cad_eur
    assert_not_nil rates = Exchange.default.source.raw_rates
    assert_not_nil rates[:USD]
    assert_not_nil usd_cad = rates[:USD][:CAD]
    assert_not_nil usd_eur = rates[:USD][:EUR]

    assert_not_nil cad = Money.new(123.45, :CAD)
    assert_not_nil eur = cad.convert(:EUR)

    assert_kind_of Numeric, m = (eur.to_f / cad.to_f)
    # $stderr.puts "m = #{m}"
    assert_equal_float (1.0 / usd_cad) * usd_eur, m, 0.001
  end

end

end # module

