# REAL

require 'test/unit'
require 'currency'

module Currency

class TestBase < Test::Unit::TestCase
  def setup
    super
  end

  # Avoid "No test were specified" error.
  def test_foo
    assert true
  end

  # Helpers.
  def assert_equal_float(x, y, eps = 1.0e-8)
    d = (x * eps).abs
    assert (x - d) <= y
    assert y <= (x + d)
  end

end # class

end # module

