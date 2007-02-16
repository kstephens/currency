# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.


# External representation mixin
class Object 
  # Exact conversion to Money representation value.
  def money(*opts)
    Currency::Money(self, *opts)
  end
end


# External representation mixin
class Integer 
  # Exact conversion to Money representation value.
  def Money_rep(currency, time = nil)
    Integer(self * currency.scale)
  end
end


# External representation mixin
class Float 
  # Inexact conversion to Money representation value.
  def Money_rep(currency, time = nil)  
    Integer(self * currency.scale) 
  end
end


# External representation mixin
class String
  # Exact conversion to Money representation value.
  def Money_rep(currency, time = nil)
    x = currency.parse(self, :currency => currency, :time => time)
    x = x.rep if x.kind_of?(Currency::Money)
    x
  end
end

