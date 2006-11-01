require 'active_record/base'
require File.join(File.dirname(__FILE__), '..', 'currency')

module Currency
  module ActiveRecord
    def self.append_features(base) # :nodoc:
      # $stderr.puts "  Currency::ActiveRecord#append_features(#{base})"
      super
      base.extend(ClassMethods)
    end
      

# == ActiveRecord Suppport
#
# This package also contains ActiveRecord support for money values:
#
#    require 'currency'
#    require 'currency/active_record'
#    
#    class Entry < ActiveRecord::Base
#       money :amount
#    end
# 
    module ClassMethods

      # Defines a Money object attribute that is bound
      # to a database column.  The database column to store the
      # Money value representation is assumed to be
      # INTEGER.
      #
      # Options:
      #
      #    :currency => :USD
      #
      # Defines the Currency to use for storing a normalized Money 
      # value.  This allows SQL summary operations, 
      # like SUM(), MAX(), AVG(), etc., to produce meaningful results,
      # regardless of the initial currency specified.  If this
      # option is used, subsequent reads will be in the specified
      # normalization :currency.  Defaults to :USD.
      #
      #    :currency_field => undef
      #
      # Defines the name of the CHAR(3) column that is used to store and
      # retrieve the Money's Currency code.  If this option is used, each
      # record may use a different Currency to store the result, such
      # that SQL summary operations, like SUM(), MAX(), AVG(), 
      # may return meaningless results.
      #
      #    :currency_preferred_field => undef
      #
      # Defines the name of a CHAR(3) column used to store and
      # retrieve the Money's Currency code.  This option can be used
      # with normalize Money values to retrieve the Money value 
      # in its original Currency, while
      # allowing SQL summary operations on a normalized Money value
      # to still be valid.
      #
      def money(attr_name, *opts)
        opts = Hash.[](*opts)

        attr_name = attr_name.to_s

        currency = opts[:currency]

        currency_field = opts[:currency_field]
        if currency_field
          currency = "read_attribute(:#{currency_field})"
        end

        currency_preferred_field = opts[:currency_preferred_field]
        if currency_preferred_field
          read_preferred_currency = "@#{attr_name} = @#{attr_name}.convert(read_attribute(:#{:currency_preferred_field}))"
          write_preferred_currency = "write_attribute(:#{currency_preferred_field}, @#{attr_name}_money.currency.code)"
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
    unless #{attr_name}_rep.nil?
      @#{attr_name} = Money.new_rep(#{attr_name}_rep, #{currency})
      #{read_preferred_currency}
    end
  end
  @#{attr_name}
end
def #{attr_name}=(value)
  if value.nil?
    ;
  elsif value.kind_of?(Integer) || value.kind_of?(String) || value.kind_of?(Float)
    #{attr_name}_money = Money.new(value, #{currency})
    #{write_preferred_currency}
  elsif value.kind_of?(Money)
    #{write_preferred_currency}
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
  # FIX ME, User cannot specify Currency
  x = #{attr_name}
  x &&= x.format(:no_symbol, :no_currency, :no_thousands)
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
