module Currency
module Exchange
  # Represents a convertion rate between two currencies
  class Rate
    def initialize(c1, c2, c1_to_c2_rate, source = "UNKNOWN", date = nil, recip = true)
      @c1 = c1
      @c2 = c2
      @rate = c1_to_c2_rate
      raise Exception::InvalidRate.new(@rate) unless @rate > 0.0
      @source = source
      @date = date || Time.now
      @reciprocal = recip
    end

    def c1
      @c1
    end

    def c2
      @c2
    end

    def rate
      @rate
    end

    def source
      @source
    end

    def date
      @date
    end

    def convert(m, c1)
      m = m.to_f	
      if ( @c1 == c1 )
        # $stderr.puts "Converting #{@c1} #{m} to #{@c2} #{m * @rate} using #{@rate}"
        m * @rate
      else
        # $stderr.puts "Converting #{@c2} #{m} to #{@c1} #{m / @rate} using #{1.0 / @rate}; recip"
        m / @rate
      end
    end
  end

  
end # module
end # module


