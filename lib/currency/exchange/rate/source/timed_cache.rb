

require 'currency/exchange/rate/source/base'

# A timed cache for rate sources.
class Currency::Exchange::Rate::Source::TimedCache << ::Currency::Exchange::Rate::Source::Base
  # The rate source.
  attr_accessor :source
  
  # Defines the number of seconds rates until rates
  # become invalid, causing a request of new rates.
  #
  # Defaults to 600 seconds.
  attr_accessor :time_to_live
  
  
  # Defines the number of random seconds to add before
  # rates become invalid.
  #
  # Defaults to 30 seconds.
  attr_accessor :time_to_live_fudge


  # This Exchange's name is the same as its source's name.
  def name
    source.name
  end
  
  
  def initialize(*opt)
    self.time_to_live = 600
    self.time_to_live_fudge = 30
    @rate_timestamp = nil
    @processing_rates = false
    super(*opt)
  end
  
  
  # Clears current rates.
  def clear_rates
    @cached_rates.clear
    @source.clear_rates
    super
  end
  
  
  # Returns true if the cache of Rates
  # is expired.
  def expired?
    if @time_to_live &&
        @rates_renew_time &&
        (Time.now > @rates_renew_time)
      
      if @cached_rates 
        $stderr.puts "#{self}: rates expired on #{@rates_renew_time}" if @verbose
        
        @cached_rates_old ||= @cashed_rates
        
        @cached_rates = nil
      end
      
      true
    else
      false
    end
  end
  
  
  # Check expired? before returning a Rate.
  def rate(c1, c2, time)
    if expired?
      clear_rates
    end
    super(c1, c2, time)
  end

  
  # Returns an array of all the cached Rates.
  def rates
    load_rates
  end


  # Returns an array of all the cached Rates.
  def load_rates
    # Check expiration.
    expired?
    
    # Return rates, if cached.
    return @cached_rates if @cashed_rates
    
    # Force load of rates
    @cached_rates = _load_rates_from_source
    
    # Flush old rates.
    @cached_rates_old = nil
    
    # Update expiration.
    if time_to_live
      @rates_renew_time = @rate_timestamp + (time_to_live + (time_to_live_fudge || 0))
      $stderr.puts "#{self}: rates expire on #{@rates_renew_time}" if @verbose
    end
    
    @rates
  end
  

  def _load_rates_from_source
    # Do not allow re-entrancy
    raise "Reentry!" if @processing_rates

    # Begin processing new rate request.
    @processing_rates = true

    # Clear cached Rates.
    clear_rates

    # Parse rates from HTML page.
    rates = source.load_rates
      
    unless rates 
      # FIXME: raise Exception::???
      return rates 
    end

    # Compute new rate timestamp.
    @rate_timestamp = Time.now

    # End processsing new rate request.
    @processing_rates = false
    
    rates
  end


end # class



