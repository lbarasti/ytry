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

The Try type represents a computation that may either result in an exception, or return a successfully computed value ([scala-docs](http://www.scala-lang.org/api/2.11.8/index.html#scala.util.Try))

[TODO]

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lbarasti/ytry. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
