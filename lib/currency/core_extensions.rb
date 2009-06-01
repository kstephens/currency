# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

require 'rational'


class Object 
  # Conversion to Money representation value.
  def money(*opts)
    Currency::Money(self, *opts)
  end
end


class Integer 
  # Exact conversion to Money representation value.
  # Do not use this method directly.
  def Money_rep(currency, time = nil)
    [ self * currency.scale, true ]
  end
end


class Rational
  # Exact or inexact conversion to Money representation value.
  # Exact if denominator after currency scaling is unity.
  # Do not use this method directly.
  def Money_rep(currency, time = nil)
    r = self * currency.scale
    [ r.to_i, r.denominator == 1 ]
  end
end


class Float 
  # Inexact conversion to Money representation value.
  # Do not use this method directly.
  def Money_rep(currency, time = nil)  
    [ (Currency::Config.current.float_ref_filter.call(self * currency.scale)).to_i, false ]
  end
end


class String
  # Exact conversion to Money representation value.
  # Do not use this method directly.
  def Money_rep(currency, time = nil)
    x = currency.parse(self, :currency => currency, :time => time)
    x = [ x.rep, x.exact? ] if x.respond_to?(:rep)
    x
  end
end

