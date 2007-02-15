 require 'active_record/base'

class Currency::Exchange::Historical::Rate < ::ActiveRecord::Base
   TABLE_NAME = 'currency_historical_rates'
   set_table_name TABLE_NAME

   def self.schema(table_name = TABLE_NAME)
     table_name = table_name.intern 
     create_table table_name do |t|
       t.column :created_on, :datetime, :null => false
       t.column :updated_on, :datetime

       t.column :c1,       :char,     :null => false
       t.column :c2,       :char,     :null => false

       t.column :source,   :string,   :null => false

       t.column :rate,     :float,    :null => false

       t.column :rate_avg, :float,
       t.column :rate_samples,  :integer,
       t.column :rate_lo,  :float,
       t.column :rate_hi,  :float,
       t.column :rate_date_0,   :float,
       t.column :rate_date_1,   :float,

       t.column :derived,  :string
       t.column :date,     :datetime, :null => false
       t.column :date_0,   :datetime, :null => false
       t.column :date_1,   :datetime, :null => false
     end
     
     add_index table_name :c1
     add_index table_name :c2
     add_index table_name :source
     add_index table_name :date
     add_index table_name :date_0
     add_index table_name :date_1
   end



   def initialize(opts = { })
     super
     if rate = opts[:rate]
       self.c1 = rate.c1.code
       self.c2 = rate.c2.code
       self.rate = rate.rate
       self.rate_avg = rate.rate_avg
       self.rate_lo  = rate.rate_lo
       self.rate_hi  = rate.rate_hi
       self.rate_date_0  = rate.rate_date_0
       self.rate_date_1  = rate.rate_date_1
       self.source = rate.source
       self.date = rate.date
       self.date_0 = rate.date_0
       self.date_1 = rate.date_1
     end
   end

   def convert_to_rate
     ::Currency::Exchange::Rate.new(
                                  Currency::Currency.get(self.c1), 
                                  Currency::Currency.get(self.c2),
                                  self.rate,
                                  "historical #{self.source}",
                                  self.date,
                                    {
                                      :rate_avg => self.rate_avg,
                                      :rate_samples => self.rate_samples,
                                      :rate_lo => self.rate_lo,
                                      :rate_hi => self.rate_hi,
                                      :rate_date_0 => self.rate_date_0,
                                      :rate_date_1 => self.rate_date_1,
                                      :date_0 => self.date_0,
                                      :date_1 => self.date_1
                                    })
   end


   def before_validation
     self.date_0 = self.date unless self.date_0
     self.date_1 = self.date unless self.date_1
   end
 end
 
