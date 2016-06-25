require_relative '../test/test_helper' # IGNORE
# IGNORE
require 'test/unit' # IGNORE
include Test::Unit::Assertions # IGNORE
include Ytry # IGNORE

same_string( # IGNORE
Try{ 1/0 }.map{|value| valule.to_s}.recover{'Infinity'}
).('Success(Infinity)') # COMMENT
