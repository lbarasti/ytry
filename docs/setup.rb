require_relative '../test/test_helper' # IGNORE
# IGNORE
require 'test/unit' # IGNORE
include Test::Unit::Assertions # IGNORE
# IGNORE
require 'ytry'
include Ytry

same_string( # IGNORE
Try { 1 + 1 }
).('Success(2)') # COMMENT

same_string( # IGNORE
Try { 1 / 0 }
).('Failure(#<ZeroDivisionError: divided by 0>)') # COMMENT
