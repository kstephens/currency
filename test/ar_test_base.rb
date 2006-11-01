require 'test/test_base'
require 'currency'

require 'rubygems'
require 'active_record'
require 'active_record/migration'
require 'currency/active_record'

AR_M = ActiveRecord::Migration
AR_B = ActiveRecord::Base

module Currency

class ArTestBase < TestBase

  ##################################################
  # Basic CurrenyTest AR::B class
  #

  TABLE_NAME = 'currency_test'

  class CurrencyTestMigration < AR_M
    def self.up
      begin
        down
      rescue Object => e
        announce("Warning: #{e}")
      end

      create_table TABLE_NAME.intern do |t|
        t.column :name,     :string
        t.column :amount,   :integer # Money
      end
    end

    def self.down
      drop_table TABLE_NAME.intern
    end
  end

  class CurrencyTest < AR_B
    set_table_name TABLE_NAME
    money :amount
  end 

  ##################################################

  def setup
    super
    AR_B.establish_connection(database_spec)

    # Subclasses can override this.
    @currency_test_migration ||= CurrencyTestMigration 
    @currency_test ||= CurrencyTest

    schema_up
  end

  def teardown
    super
    schema_down
  end

  def database_spec
    # TODO: Get from ../config/database.yml:test
    @database_spec = {
      :adapter  => "mysql",
      :host     => "localhost",
      :username => "test",
      :password => "test",
      :database => "test"
    }
  end

  def schema_up
    @currency_test_migration.migrate(:up)

  end

  def schema_down
    #@currency_test_migration.migrate(:down)
  end

  ##################################################
  # Scaffold
  # 

  def insert_records
    @currency_test.reset_column_information

    @usd = @currency_test.new(:name => '#1: USD', :amount => Money.new("12.34", :USD))
    @usd.save

    @cad = @currency_test.new(:name => '#2: CAD', :amount => Money.new("56.78", :CAD))
    @cad.save
  end

  def delete_records
    # Simp
  end

  ##################################################

  def assert_currency_test(a,b)
    assert_not_nil a
    assert_not_nil b
    # Make sure a and b are not the same object.
    assert_not_equal a.object_id, b.object_id
    assert_equal   a.id, b.id
    assert_not_nil a.amount
    assert_kind_of Money, a.amount
    assert_not_nil b.amount
    assert_kind_of Money, b.amount
    # Make sure that what gets stored in the database comes back out
    # when converted back to the original currency.
    assert_equal   a.amount.convert(b.amount.currency).rep, b.amount.rep
  end

  def test_simple
    insert_records

    assert_not_nil usd = @currency_test.find(@usd.id)
    assert_currency_test usd, @usd

    assert_equal   usd.amount.rep, @usd.amount.rep
    assert_equal   usd.amount.currency, @usd.amount.currency
    assert_equal   usd.amount.currency.code, @usd.amount.currency.code

    assert_not_nil cad = @currency_test.find(@cad.id)
    assert_currency_test cad, @cad

    assert_equal   cad.amount.currency.code, :USD

    delete_records
  end

end

end # module

