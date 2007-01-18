require 'active_record/base'
require File.join(File.dirname(__FILE__), '..', 'currency')

module ActiveRecord
  class Base
    @@money_attributes = { }

    # Called by money macro when a money attribute
    # is created.
    def self.register_money_attribute(attr_opts)
      (@@money_attributes[attr_opts[:class]] ||= { })[attr_opts[:attr_name]] = attr_opts
    end

    # Returns an array of option hashes for all the money attributes of
    # this class.
    #
    # Superclass attributes are not included.
    def self.money_attributes_for_class(cls)
      (@@money_atttributes[cls] || { }).values
    end

    # Iterates through all known money attributes in all classes.
    #
    # each_money_attribute { | money_opts |
    #   ...
    # }
    def self.each_money_attribute(&blk)
      @@money_attributes.each do | cls, hash |
        hash.each do | attr_name, attr_opts |
          yield attr_opts
        end
      end
    end

  end
end


module Currency
  module ActiveRecord
    def self.append_features(base) # :nodoc:
      # $stderr.puts "  Currency::ActiveRecord#append_features(#{base})"
      super
      base.extend(ClassMethods)
    end



# == ActiveRecord Suppport
#
# Support for Money attributes in ActiveRecord::Base subclasses:
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
      #    :column => undef
      #
      # Defines the column to use for storing the money value.
      # Defaults to the attribute name.
      #
      #    :currency => :USD
      #
      # Defines the Currency to use for storing a normalized Money 
      # value.  
      #
      # All Money values will be converted to this Currency before
      # storing in the column.  This allows SQL summary operations, 
      # like SUM(), MAX(), AVG(), etc., to produce meaningful results,
      # regardless of the initial currency specified.  If this
      # option is used, subsequent reads will be in the specified
      # normalization :currency.  Defaults to :USD.
      #
      #    :currency_column => undef
      #
      # Defines the name of the CHAR(3) column used to store and
      # retrieve the Money's Currency code.  If this option is used, each
      # record may use a different Currency to store the result, such
      # that SQL summary operations, like SUM(), MAX(), AVG(), 
      # may return meaningless results.
      #
      #    :currency_preferred_column => undef
      #
      # Defines the name of a CHAR(3) column used to store and
      # retrieve the Money's Currency code.  This option can be used
      # with normalized Money values to retrieve the Money value 
      # in its original Currency, while
      # allowing SQL summary operations on the normalized Money values
      # to still be valid.
      #
      #    :time => undef
      #
      # Defines the name of attribute used to 
      # retrieve the Money's time.  If this option is used, each
      # Money value will use this attribute during historical Currency
      # conversions.
      #
      # Money values can share a time value with other attributes
      # (e.g. a created_on column).
      #
      # If this option is true, the money time attribute will be named
      # "#{attr_name}_time" and :time_update will be true.
      #
      #    :time_update => undef
      #
      # If true, the Money time value is updated upon setting the
      # money attribute.  
      #
      def money(attr_name, *opts)
        opts = Hash[*opts]

        attr_name = attr_name.to_s
        opts[:class] = self
        opts[:table] = self.table_name
        opts[:attr_name] = attr_name.intern
        ::ActiveRecord::Base.register_money_attribute(opts)

        column = opts[:column] || opts[:attr_name]
        opts[:column] = column

        currency = opts[:currency]

        currency_column = opts[:currency_column]
        if currency_column && ! currency_column.kind_of?(String)
          currency_column = currency_column.to_s
          currency_column = "#{column}_currency"
        end
        if currency_column
          read_currency = "read_attribute(:#{currency_column.to_s})"
          write_currency = "write_attribute(:#{currency_column}, #{attr_name}_money.nil? ? nil : #{attr_name}_money.currency.code.to_s)"
        end
        opts[:currency_column] = currency_column

        currency_preferred_column = opts[:currency_preferred_column]
        if currency_preferred_column
          currency_preferred_column = currency_preferred_column.to_s
          read_preferred_currency = "@#{attr_name} = @#{attr_name}.convert(read_attribute(:#{currency_preferred_column}))"
          write_preferred_currency = "write_attribute(:#{currency_preferred_column}, @#{attr_name}_money.currency.code)"
        end

        time = opts[:time]
        write_time = ''
        if time
          if time == true
            time = "#{attr_name}_time"
            opts[:time_update] = true
          end
          read_time = "self.#{time}"
        end
        opts[:time] = time
        if opts[:time_update]
          write_time = "self.#{time} = #{attr_name}_money && #{attr_name}_money.time"
        end

        currency ||= ':USD'
        time ||= 'nil'

        read_currency ||= currency
        read_time ||= time

        money_rep ||= "#{attr_name}_money.rep"

        validate = "# Validation\n"
        validate << "\nvalidates_numericality_of :#{attr_name}\n" unless opts[:allow_nil]
        validate << "\nvalidates_format_of :#{currency_column}, :with => /^[A-Z][A-Z][A-Z]$/\n" if currency_column && ! opts[:allow_nil]

        module_eval (x = <<-"end_eval"), __FILE__, __LINE__
#{validate}

def #{attr_name}
  # $stderr.puts "  \#{self.class.name}##{attr_name}"
  unless @#{attr_name}
    #{attr_name}_rep = read_attribute(:#{column})
    unless #{attr_name}_rep.nil?
      @#{attr_name} = Currency::Money.new_rep(#{attr_name}_rep, #{read_currency} || #{currency}, #{read_time} || #{time})
      #{read_preferred_currency}
    end
  end
  @#{attr_name}
end

def #{attr_name}=(value)
  if value.nil?
    #{attr_name}_money = nil
  elsif value.kind_of?(Integer) || value.kind_of?(String) || value.kind_of?(Float)
    #{attr_name}_money = ::Currency::Money(value, #{currency})
    #{write_preferred_currency}
  elsif value.kind_of?(::Currency::Money)
    #{attr_name}_money = value
    #{write_preferred_currency}
    #{write_currency ? write_currency : "#{attr_name}_money = #{attr_name}_money.convert(#{currency})"}
  else
    throw Currency::Exception::InvalidMoneyValue.new(value)
  end

  @#{attr_name} = #{attr_name}_money
  
  write_attribute(:#{column}, #{attr_name}_money.nil? ? nil : #{money_rep})
  #{write_time}

  value
end

def #{attr_name}_before_type_cast
  # FIXME: User cannot specify Currency
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
