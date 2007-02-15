module Currency
module Exchange
  # Represents a convertion rate between two currencies
  class Rate
    # The first Currency.
    attr_reader :c1

    # The second Currency.
    attr_reader :c2

    # The rate between _c1_ and _c2_.
    # to convert between m1 in _c1_ and m2 in _c2_,
    # m2 = m1 * _rate_.
    attr_reader :rate

    # The source of the rate.
    attr_reader :source

    # The Time of the rate.
    attr_reader :date

    # If the rate is derived from other rates, this describes from where it was derived.
    attr_reader :derived

    # Extended Attributes
    attr_reader :rate_avg
    attr_reader :rate_lo
    attr_reader :rate_hi
    attr_reader :rate_date_0
    attr_reader :rate_date_1
    attr_reader :date_0
    attr_reader :date_1

    def initialize(c1, c2, c1_to_c2_rate, source = "UNKNOWN", date = nil, derived = nil, reciprocal = nil, opts = nil)
      @c1 = c1
      @c2 = c2
      @rate = c1_to_c2_rate
      raise Exception::InvalidRate.new(@rate) unless @rate >= 0.0
      @source = source
      @date = date || Time.now
      @derived = derived
      @reciprocal = reciprocal

      if opts
        opts.each_pair do | k, v |
          self.instance_variable_set("@#{k}", v)
        end
      end
    end


    # Returns a cached reciprocal Rate object from c2 to c1.
    def reciprocal
      @reciprocal ||= self.class.new(@c2, @c1, 1.0 / @rate, @source, @date, "reciprocal: #{self.derived}", self,
                                     { 
                                       :rate_avg     => @rate_avg    && 1.0 / @rate_avg,
                                       :rate_samples => @rate_samples,                            
                                       :rate_lo      => @rate_lo     && 1.0 / @rate_lo,
                                       :rate_hi      => @rate_hi     && 1.0 / @rate_hi,
                                       :rate_date_0  => @rate_date_0 && 1.0 / @rate_date_0,
                                       :rate_date_1  => @rate_date_1 && 1.0 / @rate_date_1,
                                       :date_0       => @date_0,
                                       :date_1       => @date_1,
                                     }
                                     )
    end


    # Converts from _m_ in Currency _c1_ to the opposite currency.
    def convert(m, c1)
      m = m.to_f	
      if @c1 == c1
        # $stderr.puts "Converting #{@c1} #{m} to #{@c2} #{m * @rate} using #{@rate}"
        m * @rate
      else
        # $stderr.puts "Converting #{@c2} #{m} to #{@c1} #{m / @rate} using #{1.0 / @rate}; recip"
        m / @rate
      end
    end


    # Collect rate samples into rate_avg, rate_hi, rate_lo, rate_0, rate_1, date_0, date_1.
    def collect_rates(rates)
      rates = [ rates ] unless rates.kind_of?(Enumerable)
      rates.each do | r |
        collect_rate(r)
      end
      self
    end


    def collect_rate(rate)
      # Initial.
      @rate_samples ||= 0
      @rate_sum ||= 0
      @src ||= rate
      @c1 ||= rate.c1
      @c2 ||= rate.c2
      @date ||= rate.date
      @src ||= rate.src

      # Reciprocal?
      if @c1 == rate.c2 && @c2 == rate.c1
        collect_rate(rate.reciprocal)
      elsif ! (@c1 == rate.c1 && @c2 == rate.c2)
        raise("Cannot collect rates between different currency pairs")
      else
        # Multisource?
        @src = "<<multiple-sources>>" unless @src == rate.source

        # Calculate rate average.
        @rate_samples += 1
        @rate_sum += rate.rate || (rate.rate_lo + rate.rate_hi) * 0.5
        @rate_avg = @rate_sum / @rate_samples

        # Calculate rates ranges.
        r = rate.rate_lo || rate.rate
        unless @rate_lo && @rate_lo < r
          @rate_lo = r
        end
        r = rate.rate_hi || rate.rate
        unless @rate_hi && @rate_hi > r
          @rate_hi = r
        end

        # Calculate rates on date range boundaries
        r = rate.rate_date_0 || rate.rate
        d = rate.date_0 || rate.date
        unless @date_0 && @date_0 < d
          @date_0 = d
          @rate_0 = r
        end

        r = rate.rate_date_1 || rate.rate
        d = rate.date_1 || rate.date
        unless @date_1 && @date_1 > d
          @date_1 = d 
          @rate_0 = r
        end

        @date ||= rate.date || rate.date0 || rate.date1
      end
      self
    end


    def to_s(extended = false)
      extended = "#{date_0} #{rate_0} |< #{rate_lo} #{rate} #{rate_hi} >| #{rate_1} #{date_1}" if extended
      extended ||= ''
      "#<#{self.class.name} #{c1.code} #{c2.code} #{rate} #{source.inspect} #{date.xmlschema} #{derived} #{extended}>"
    end

    def inspect; to_s; end
  end

  
end # module
end # module


