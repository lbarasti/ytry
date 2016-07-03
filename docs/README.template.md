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
<<<<<docs/setup.rb
```

`Success` and `Failure` provide a unified API that lets us express a sequence of tranformations in a fluent way, without error handling cluttering the flow:

```ruby
<<<<<docs/basics.rb
```

`Try#map` and `Try#recover` are means to interact with the value wrapped by a Try in a safe way - i.e. with no risk of errors being raised.

`Try#select` transforms a Success into a Failure when the underlying value does not satisfy the given predicate - i.e. the given block returns false. That can be useful when validating some input.

`Try#get_or_else` provides a safe way of retrieving the possibly-missing value it contains. It returns the result of the given block when the Try is a Failure. It is equivalent to `Try#get` when the Try is a Success.

```ruby
<<<<<docs/get_or_else.rb
```

It is preferable to use `Try#get_or_else` over `Try#get`, as `#get` will raise an error when called on a Failure. It is possible to check for failure via `#empty?`, but that tipically leads to non-idiomatic code

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lbarasti/ytry. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

