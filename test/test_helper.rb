require 'coveralls'
Coveralls.wear!

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ytry'

require 'minitest/autorun'
require 'minitest/unit'
include MiniTest::Assertions

@assertions = 0
def assertions; @assertions; end
def assertions= other; @assertions = other; end

def same_string(exp1)
  -> exp2 {assert_equal(exp1.to_s, exp2); exp1}
end
