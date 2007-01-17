# Connects to http://xe.com and parses "XE.com Quick Cross Rates"
# from home page HTML.
#
# This is for demonstration purposes.
#

require 'active_record/base'

module Currency
module Exchange

  class Historical < Base
    class Rate < ::ActiveRecord::Base
      TABLE_NAME = 'currency_historical_rates'
      set_table_name TABLE_NAME

      def self.schema(table_name = TABLE_NAME)
        table_name = table_name.intern 
        create_table table_name do |t|
          t.column :c1,       :char,     :null => false
          t.column :c2,       :char,     :null => false
          t.column :rate,     :float,    :null => false
          t.column :rate_avg, :float,
          t.column :rate_hi,  :float,
          t.column :rate_lo,  :float,
          t.column :rate_0,   :float,
          t.column :rate_1,   :float,
          t.column :src,      :string,   :null => false
          t.column :date,     :datetime, :null => false
          t.column :date_0,   :datetime, :null => false
          t.column :date_1,   :datetime, :null => false
        end

        add_index table_name :c1
        add_index table_name :c2
        add_index table_name :src
        add_index table_name :date
        add_index table_name :date_0
        add_index table_name :date_1
      end
    end

    # Select specific rate source.
    # Defaults to nil
    attr_accessor :source

    # Defines the pivot currency.
    PIVOT_CURRENCY = :USD

    # This Exchange's name is the same as its #uri.
    def name
      "historical #{source}"
    end


    def initialize(*opt)
      @rate_cache = nil
      super(*opt)
    end


    def clear_rates
      @rate_cache && @rate_cache.clear
      super
    end


    # Loads cached rates from xe.com and creates Rate objects
    # for 10 currencies.
    def get_rate(c1, c2, time)
      rates = get_rates(time)
 
      # Use USD as pivot to convert between c1 and c2.
      if ( c1.code == PIVOT_CURRENCY && (r2 = rates_pivot[c2.code]) )
        rate = r2
      elsif ( c2.code == PIVOT_CURRENCY && (r1 = rates_pivot[c2.code]) )
        rate = 1.0 / r1
      elsif ( (r1 = rates_pivot[c1.code]) && (r2 = rates_pivot[c2.code]) )
        rate = r2 / r1
      end

      # $stderr.puts "Historical Rate: #{c1.code} / #{c2.code} = #{rate}"

      rate > 0 ? new_rate(c1, c2, rate, @rate_timestamp) : nil
    end


    # Return a list of base rates.
    def get_rates(time)
      raw_rates = get_raw_rates(time)

      rates = raw_rates.each do | raw_rate |
        rate = new_rate(raw_rate.c1, rate_rate.c2, raw_rate.rate, raw_rate.date)
      end

      rates
    end


    def get_raw_rates(time, src)
      condition_sql = 'date_0 < ? AND date_1 <= ?'
      conditions = [ time, time ]
      if src
        condition_sql += ' AND src = ?'
        conditions << src
      end

      conditions_value.unshift(conditions_sql)
      raw_rates = Rate.find(:all, :condition => conditions)

      raw_rates
    end

  end # class

end # module
end # module


# Install as default.
# Currency::Exchange.default = Currency::Exchange::Xe.instance

