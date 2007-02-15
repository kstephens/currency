
module Currency
module Exchange
class Historical
class Writer
  # The source of rates.
  attr_accessor :source

  # If true, compute all Rates between rates.
  attr_accessor :compute_all_rates

  # If true, store unity rates.
  # This can be used to aid complex joins.
  attr_accessor :store_unity_rates

  # If set, use this time quantitizer to
  # manipulate the Rate date_0 date_1 time ranges.
  attr_accessor :time_quantitizer


  def initialize(opt = { })
    super
    opt.each_pair{|k,v| self.send("#{k}=", v)}
  end


  def write_rates
    # Get Rates from source.
    rates = source.rates

    # Produce a list of all currencies.
    currencys = rates.collect{| r | [ r.c1, r.c2 ]}.flatten.uniq

    # Produce Rates for all pairs of currencies.
    all_rates = [ ]
    currencys.each do | c1 |
      currencys.each do | c2 |
        rate = source.rate(c1, c2)
        all_rates << rate
      end
    end


    # Create Historical::Rate objects.
    h_rate_class = ::Currency::Exchange::Historical::Rate

    # Most Rates from the same Source will probably have the same time,
    # so cache the computed date_range.
    date_range_cache = { } 

    h_rates = rates.collect do | r |
      rr = h_rate_class.new.from_rate(r)
      if time_quantitizer
        date_range = date_range_cache[r.date] ||= time_quantitizer.time_range
        rr.date_0 = date_range.begin
        rr.date_1 = date_range.end
      end
      rr
    end

    # Save them all or none.
    h_rate_class.transaction do 
      h_rates.each do | rr |
        rr.save!
      end
    end
  end

end # class

end # class
end # module
end # module


