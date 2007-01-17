module Currency
module Exchange
  # Represents a convertion rate between two currencies
  class Rate
    def initialize(c1, c2, c1_to_c2_rate, source = "UNKNOWN", date = nil, derived = nil, reciprocal = nil)
      @c1 = c1
      @c2 = c2
      @rate = c1_to_c2_rate
      raise Exception::InvalidRate.new(@rate) unless @rate > 0.0
      @source = source
      @date = date || Time.now
      @derived = derived
      @reciprocal = reciprocal
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


    def derived
      @dervied
    end


    def reciprocal
      @reciprocal ||= self.class.new(@c2, @c1, 1.0 / @rate, @source, @date, "reciprocal: #{self.derived}", self)
    end


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

    def to_s
      "#<#{self.class.name} #{c1.code} #{c2.code} #{rate} #{source.name} #{date} #{derived}>"
    end

  end

  
end # module
end # module


