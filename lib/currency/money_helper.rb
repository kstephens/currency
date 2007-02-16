# Copyright (C) 2006-2007 Kurt Stephens <ruby-currency(at)umleta.com>
# See LICENSE.txt for details.

module ActionView
 module Helpers
   module MoneyHelper
     def money_field(object, method, options = {})
       InstanceTag.new(object, method, self).to_input_field_tag("text", options)
     end
   end
 end
end


ActionView::Base.load_helper(File.dirname(__FILE__))
