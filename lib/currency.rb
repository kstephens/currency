
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'currency/exception'
require 'currency/money'
require 'currency/currency_factory'
require 'currency/currency'
require 'currency/money'
require 'currency/exchange'
require 'currency/core_extensions'

