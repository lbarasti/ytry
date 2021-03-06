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
  -> exp2 {assert_equal(exp2, exp1.to_s); exp1}
end

def new_flag
  initial_value, current_value, toggle_value = -> {init = false; flag = init; [init, -> {flag}, -> {flag = !flag}]}.()
end