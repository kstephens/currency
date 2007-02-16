
module Currency
module Exchange
class Historical

# Responsible for writing
class Writer
  # The source of rates.
  attr_accessor :source

  # If true, compute all Rates between rates.
  # This can be used to aid complex join reports that may assume
  # c1 as the from currency and c2 as the to currency.
  attr_accessor :all_rates

  # If true, store identity rates.
  # This can be used to aid complex join reports.
  attr_accessor :identity_rates

  # If set, a set of preferred currencies.
  attr_accessor :preferred_currencies

  # If set, a list of required currencies.
  attr_accessor :required_currencies

  # If set, a list of required base currencies.
  # base currencies must have rates as c1.
  attr_accessor :base_currencies

  # If true, compute and store all reciprocal rates.
  attr_accessor :reciprocal_rates

  # If set, use this time quantitizer to
  # manipulate the Rate date_0 date_1 time ranges.
  attr_accessor :time_quantitizer


  def initialize(opt = { })
    @identity_rates = false
    @preferred_currencies = nil
    @base_currencies = nil
    @time_quantitizer = nil
    opt.each_pair{| k, v | self.send("#{k}=", v) }
  end


  def selected_rates
    # Produce a list of all currencies.
    currencies = source.currencies

    selected_rates = [ ]

    # Get list of preferred_currencies.
    if preferred_currencies
      currencies = currencies.select{ | c | preferred_currencies.include?(c)}.uniq
    end


    # Check for required currencies.
    if required_currencies
      required_currencies.each do | c |
        currencies.include?(c) || raise("Required currency #{c.inspect} not in #{currencies.inspect}")
      end
    end


    $stderr.puts "currencies = #{currencies.inspect}"

    deriver = ::Currency::Exchange::Rate::Deriver.new(:source => source)

    # Produce Rates for all pairs of currencies.
    if all_rates
      currencies.each do | c1 |
        currencies.each do | c2 |
          next if c1 == c2
          c1 = ::Currency::Currency.get(c1)
          c2 = ::Currency::Currency.get(c2)
          rate = deriver.rate(c1, c2, nil)
          selected_rates << rate unless selected_rates.include?(rate)
        end
      end
    elsif base_currencies
      base_currencies.each do | c1 |
        currencies.each do | c2 |
          next if c1 == c2
          c1 = ::Currency::Currency.get(c1)
          c2 = ::Currency::Currency.get(c2)
          rate = deriver.rate(c1, c2, nil)
          selected_rates << rate unless selected_rates.include?(rate)
        end
      end
    else
      selected_rates = source.rates.select do | r |
        currencies.include?(r.c1.code) && currencies.include?(r.c2.code)
      end
    end

    if identity_rates
      currencies.each do | c1 |
        c1 = ::Currency::Currency.get(c1)
        c2 = c1
        rate = deriver.rate(c1, c2, nil)
        selected_rates << rate unless selected_rates.include?(rate)
      end
    end

    if reciprocal_rates
      selected_rates.clone.each do | r |
        c1 = r.c2
        c2 = r.c1
        rate = deriver.rate(c1, c2, nil)
        selected_rates << rate unless selected_rates.include?(rate)
      end
    end

    $stderr.puts "selected_rates = #{selected_rates.inspect}\n [#{selected_rates.size}]"

    selected_rates
  end


  def write_rates(rates = selected_rates)
 
    # Create Historical::Rate objects.
    h_rate_class = ::Currency::Exchange::Historical::Rate

    # Most Rates from the same Source will probably have the same time,
    # so cache the computed date_range.
    date_range_cache = { } 
    rate_0 = nil
    if time_quantitizer = self.time_quantitizer
      time_quantitizer = ::Currency::Exchange::TimeQuantitizer.current if time_quantitizer == :current
    end

    h_rates = rates.collect do | r |
      rr = h_rate_class.new.from_rate(r)
      rr.dates_to_localtime!

      if rr.date && time_quantitizer
        date_range = date_range_cache[rr.date] ||= time_quantitizer.quantitize_time_range(rr.date)
        rr.date_0 = date_range.begin
        rr.date_1 = date_range.end
      end

      rate_0 ||= rr if rr.date_0 && rr.date_1

      rr
    end

    # Fix any dateless Rates.
    if rate_0
      h_rates.each do | rr |
        rr.date_0 = rate_0.date_0 unless rr.date_0
        rr.date_1 = rate_0.date_1 unless rr.date_1
      end
    end

    # Save them all or none.
    h_rate_class.transaction do 
      h_rates.each do | rr |
        rr.save!
      end
    end

   h_rates
  end

end # class

end # class
end # module
end # module


