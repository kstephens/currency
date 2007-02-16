require 'test/ar_test_base'

require 'rubygems'
require 'active_record'
require 'active_record/migration'

require 'currency' # For :type => :money
require 'currency/exchange/historical/writer'
require 'currency/exchange/historical/rate'

require 'currency/exchange/rate/source/xe'
require 'currency/exchange/rate/source/new_york_fed'


module Currency

class HistoricalWriterTest < ArTestBase

  TABLE_NAME = Exchange::Historical::Rate.table_name

  class HistoricalRateMigration < AR_M
    def self.up
      Exchange::Historical::Rate.__create_table(self)
    end

    def self.down
      drop_table TABLE_NAME.intern
    end
  end


  def initialize(*args)
    @currency_test_migration = HistoricalRateMigration
    super
    @src = Exchange::Rate::Source::Xe.new
    @src2 = Exchange::Rate::Source::NewYorkFed.new
  end


  def setup
    super
    
  end

  
  def test_writer
    assert_not_nil src = @src
    assert_not_nil writer = Exchange::Historical::Writer.new()
    writer.time_quantitizer = :current
    writer.required_currencies = [ :USD, :GBP, :EUR, :CAD ]
    writer.base_currencies = [ :USD ]
    writer.preferred_currencies = writer.required_currencies
    writer.reciprocal_rates = true
    writer.all_rates = true
    
    writer
  end
  

  def test_writer_src
    writer = test_writer
    writer.source = @src
    rates = writer.write_rates
    assert_h_rates(rates, writer)
  end


  def test_writer_src2
    writer = test_writer
    writer.source = @src2
    rates = writer.write_rates
    assert_h_rates(rates, writer)
  end


  def test_required_failure
    assert_not_nil writer = Exchange::Historical::Writer.new()
    assert_not_nil src = @src
    writer.source = src
    writer.required_currencies = [ :USD, :GBP, :EUR, :CAD, :ZZZ ]
    writer.preferred_currencies = writer.required_currencies
    assert_raises(::RuntimeError) { writer.selected_rates }
  end


  def assert_h_rates(rates, writer = nil)
    assert_not_nil hr0 = rates[0]
    rates.each do | hr |
      assert_equal hr0.date_0, hr.date_0
      assert_equal hr0.date_1, hr.date_1
      assert_equal writer.source.name, hr.source if writer
      assert_equal hr0.source, hr.source
      assert_equal hr.rate, hr.rate_avg
      assert_equal hr.rate_samples, 1
      assert_equal hr.rate, hr.rate_lo
      assert_equal hr.rate, hr.rate_hi
      assert_equal hr.rate, hr.rate_date_0
      assert_equal hr.rate, hr.rate_date_1
    end
  end

end

end # module

