require 'active_record/base'

class Currency::Exchange::Historical::Rate < ::ActiveRecord::Base
   TABLE_NAME = 'currency_historical_rates'
   set_table_name TABLE_NAME

   def self.__create_table(m, table_name = TABLE_NAME)
     table_name = table_name.intern 
     m.instance_eval do 
       create_table table_name do |t|
         t.column :created_on, :datetime, :null => false
         t.column :updated_on, :datetime
         
         t.column :c1,       :string,     :limit => 3, :null => false
         t.column :c2,       :string,     :limit => 3, :null => false
         
         t.column :source,   :string,     :limit => 32, :null => false
         
         t.column :rate,     :float,    :null => false
         
         t.column :rate_avg,      :float
         t.column :rate_samples,  :integer
         t.column :rate_lo,       :float
         t.column :rate_hi,       :float
         t.column :rate_date_0,   :float
         t.column :rate_date_1,   :float
         
         t.column :date,     :datetime, :null => false
         t.column :date_0,   :datetime, :null => false
         t.column :date_1,   :datetime, :null => false

         t.column :derived,  :string,   :limit => 64
       end
       
       add_index table_name, :c1
       add_index table_name, :c2
       add_index table_name, :source
       add_index table_name, :date
       add_index table_name, :date_0
       add_index table_name, :date_1
       add_index table_name, [:c1, :c2, :source, :date_0, :date_1], :name => 'c1_c2_src_date_range', :unique => true
     end
   end


   def from_rate(rate)
     self.c1 = rate.c1.code.to_s
     self.c2 = rate.c2.code.to_s
     self.rate = rate.rate
     self.rate_avg = rate.rate_avg
     self.rate_lo  = rate.rate_lo
     self.rate_hi  = rate.rate_hi
     self.rate_date_0  = rate.rate_date_0
     self.rate_date_1  = rate.rate_date_1
     self.source = rate.source
     self.derived = rate.derived
     self.date = rate.date
     self.date_0 = rate.date_0
     self.date_1 = rate.date_1
     self
   end


   def dates_to_localtime!
     self.date   = self.date   && self.date.clone.localtime
     self.date_0 = self.date_0 && self.date_0.clone.localtime
     self.date_1 = self.date_1 && self.date_1.clone.localtime
   end


   def to_rate
     ::Currency::Exchange::Rate.new(
                                  ::Currency::Currency.get(self.c1), 
                                  ::Currency::Currency.get(self.c2),
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
     self.rate_avg = self.rate unless self.rate_avg
     self.rate_samples = 1 unless self.rate_samples
     self.rate_lo = self.rate unless self.rate_lo
     self.rate_hi = self.rate unless self.rate_hi
     self.rate_date_0 = self.rate unless self.rate_date_0
     self.rate_date_1 = self.rate unless self.rate_date_1

     self.date_0 = self.date unless self.date_0
     self.date_1 = self.date unless self.date_1
     self.date = self.date_0 + (self.date_1 - self.date_0) * 0.5 if ! self.date && self.date_0 && self.date_1
     self.date = self.date_0 unless self.date
     self.date = self.date_1 unless self.date
   end


 end # class

 
