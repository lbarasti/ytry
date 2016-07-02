require_relative '../test/test_helper' # IGNORE
# IGNORE
require 'test/unit' # IGNORE
include Test::Unit::Assertions # IGNORE
include Ytry # IGNORE

base_dir = __FILE__.split('/')[0...-1].join('/')
nonexisting_file = "#{base_dir}/data/not_found.json"
wrong_format_file = "#{base_dir}/data/wrong_format.json"
actual_file = "#{base_dir}/data/users.json"

def load_and_parse json_file
  Try { File.read(json_file) }
    .map {|content| JSON.parse(content)}
    .select {|table| table.is_a? Array}
    .recover {|e| puts "Recovering from #{e.message}"; []}
end

same_string( # IGNORE
load_and_parse(nonexisting_file) # prints "Recovering from No such file..."
).('Success([])') # COMMENT

same_string( # IGNORE
load_and_parse(wrong_format_file) # prints "Recovering from Element not found"
).('Success([])') # COMMENT

same_string( # IGNORE
load_and_parse(actual_file)
).('Success([{"id"=>1, "name"=>"Lorenzo", "dob"=>"22/07/1985"}])') # COMMENT
