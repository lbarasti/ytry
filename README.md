[![Gem Version](https://badge.fury.io/rb/ytry.svg)](https://badge.fury.io/rb/ytry)
[![Build Status](https://travis-ci.org/lbarasti/ytry.svg?branch=master)](https://travis-ci.org/lbarasti/ytry) [![Coverage Status](https://coveralls.io/repos/github/lbarasti/ytry/badge.svg?branch=master)](https://coveralls.io/github/lbarasti/ytry?branch=master)

# Ytry

A [Scala](http://www.scala-lang.org/api/current/index.html#scala.util.Try) inspired gem that introduces `Try`s to Ruby while aiming for an idiomatic API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ytry'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ytry

## Basic usage

The Try type represents a computation that may either result in an error, or return a successfully computed value.

If the block passed to Try runs with no errors, then a `Success` wrapping the computed value is returned.

An instance of `Failure` wrapping the error is returned otherwise.

```ruby
require 'ytry'
include Ytry

Try { 1 + 1 } # Success(2)

Try { 1 / 0 } # Failure(#<ZeroDivisionError: divided by 0>)
```

`Success` and `Failure` provide a unified API that lets us express a sequence of tranformations in a fluent way, without error handling cluttering the flow:

```ruby
def load_and_parse json_file
  Try { File.read(json_file) }
    .map {|content| JSON.parse(content)}
    .select {|table| table.is_a? Array}
    .recover {|e| puts "Recovering from #{e.message}"; []}
end

load_and_parse(nonexisting_file) # prints "Recovering from No such file..." # Success([])

load_and_parse(wrong_format_file) # prints "Recovering from Element not found" # Success([])

load_and_parse(actual_file) # Success([{"id"=>1, "name"=>"Lorenzo", "dob"=>"22/07/1985"}])
```

`Try#map` and `Try#recover` are means to interact with the value wrapped by a Try in a safe way - i.e. with no risk of errors being raised.

`Try#select` transforms a Success into a Failure when the underlying value does not satisfy the given predicate - i.e. the given block returns false. That can be useful when validating some input.

`Try#get_or_else` provides a safe way of retrieving the possibly-missing value it contains. It returns the result of the given block when the Try is a Failure. It is equivalent to `Try#get` when the Try is a Success.

```ruby
invalid_json = "[\"missing_quote]"

Try { JSON.parse(invalid_json) }
  .get_or_else{ [] } # []

Try { JSON.parse("[]") }
  .get_or_else { fail "this block is ignored"} # []
```

It is preferable to use `Try#get_or_else` over `Try#get`, as `#get` will raise an error when called on a Failure. It is possible to check for failure via `#empty?`, but that tipically leads to non-idiomatic code

## Why Try?

Using Try instead of rescue blocks can make your software both clearer and safer as it

- leads to less verbose error handling
- simplifies the way we deal with operations that might fail for several reasons (such as IO operations)
- privileges method chaining thus reducing the need for auxiliary variables to store intermediate results in a computation
- encourages programming towards immutability, where the data is transformed rather than mutated in place.

## Advanced Usage
### #reduce
Given a Try instance `try`, a value `c` and a lambda `f`,
```
try.reduce(c, &f)
```
returns `f.(c, try)` if `try` is a `Success` AND the evaluation of the lambda `f` did not throw any error, it returns `c` otherwise.

This is a shortcut to
```
try.map{|v| f.(c,v)}.get_or_else {c}
```


### #flatten
When dealing with nested `Try`s we can use flatten to reduce the level of nesting
```
success = Try{:ok}
failure = Try{fail}
Try{success}.flatten # Success(:ok)
Try{failure}.flatten # Failure(RuntimeError)
```

### Interoperability with Array-like obects
Because of it's ary-like nature, instances of `Try` play well with Array instances. In particular, flattening an Array of `Try`s is equivalent to filtering out the `Failures` from the array and then calling #get on the Success instances
```
(1..4).map{|v| Try{v}.select(&:odd?)}
      .flatten # [1, 3]
```
Behind the scenes `Array#flatten` is iterating over the collection and concatenating the ary-representation of each element.
Now `Failure#to_ary` returns `[]`, while `Success#to_ary` returns `[v]` - where `v` is the value wrapped by Success - and that does the trick.

We can squeeze the code listed above even more with `Array#flat_map`
```
(1..4).flat_map{|v| Try{v}.select(&:odd?)} # [1, 3]
```
Again, there is no magic behind this behaviour, we are just exploiting Ruby's duck typing.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lbarasti/ytry. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
