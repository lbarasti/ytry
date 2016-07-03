require_relative '../test/test_helper' # IGNORE
# IGNORE
require 'test/unit' # IGNORE
include Test::Unit::Assertions # IGNORE
include Ytry # IGNORE
# IGNORE
invalid_json = "[\"missing_quote]"

same_string( # IGNORE
Try { JSON.parse(invalid_json) }
  .get_or_else{ [] }
).('[]') # COMMENT

same_string( # IGNORE
Try { JSON.parse("[]") }
  .get_or_else { fail "this block is ignored"}
).('[]') # COMMENT
