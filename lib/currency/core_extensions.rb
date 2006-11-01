# External representation mixin
class Integer 
  # Exact
  def Money_rep(currency)
    Integer(self * currency.scale)
  end
end


# External representation mixin
class Float 
  # Inexact
  def Money_rep(currency)  
    Integer(self * currency.scale) 
  end
end


# External representation mixin
class String
  # Exact
  def Money_rep(currency)
    x = currency.parse(self, :currency => currency)
    x.rep if x.kind_of?(Currency::Money)
    x
  end
end

