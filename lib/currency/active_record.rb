require 'active_record/base'
require File.join(File.dirname(__FILE__), '..', 'currency')

module Currency
  module ActiveRecord
    def self.append_features(base) # :nodoc:
      # $stderr.puts "  Currency::ActiveRecord#append_features(#{base})"
      super
      base.extend(ClassMethods)
    end
      
    module ClassMethods
      def money(attr_name, *opts)
        opts = Hash[*opts]

        attr_name = attr_name.to_s

        currency = opts[:currency]

        currency_field = opts[:currency_field]
        if currency_field
          currency = "read_attribute(:#{currency_field})"
        end

        currency ||= ':USD'

        validate = ''
        validate = "validates_numericality_of :#{attr_name}" unless opts[:allow_nil]

        module_eval (x = <<-"end_eval"), __FILE__, __LINE__
#{validate}
def #{attr_name}
  # $stderr.puts "  \#{self.class.name}##{attr_name}"
  unless @#{attr_name}
    #{attr_name}_rep = read_attribute(:#{attr_name})
    @#{attr_name} = Money.new_rep(#{attr_name}_rep, #{currency}) unless #{attr_name}_rep.nil?
  end
  @#{attr_name}
end
def #{attr_name}=(value)
  if value.nil?
    ;
  elsif value.kind_of?(Integer) || value.kind_of?(String) || value.kind_of?(Float)
    #{attr_name}_money = Money.new(value, #{currency})
  elsif value.kind_of?(Money)
    #{attr_name}_money = value.convert(#{currency})
  else
    throw "Bad money format \#{value.inspect}"
  end
  @#{attr_name} = #{attr_name}_money
  #{currency_field ? 'write_attribute(:#{currency_field}, #{attr_name}_money.nil? ? nil : #{attr_name}_money.currency.name)' : ''}
  write_attribute(:#{attr_name}, #{attr_name}_money.nil? ? nil : #{attr_name}_money.rep)
  value
end
def #{attr_name}_before_type_cast
  x = #{attr_name}
  x &&= x.format(:no_symbol, :no_currency)
  x
end
end_eval
        # $stderr.puts "   CODE = #{x}"
      end
    end
  end
end


ActiveRecord::Base.class_eval do
  include Currency::ActiveRecord
end
