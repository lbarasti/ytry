# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ytry/version'

Gem::Specification.new do |spec|
  spec.name          = "ytry"
  spec.version       = Ytry::VERSION
  spec.authors       = ["lorenzo.barasti"]
  spec.email         = "ytry-user-group@googlegroups.com"

  spec.summary       = %q{Scala-inspired Trys for the idiomatic Rubyist}
  spec.description   = %q{"The Try type represents a computation that may either result in an exception, or return a successfully computed value." (From the scala-docs for scala.util.Try)}
  spec.homepage      = "http://lbarasti.github.io/ytry"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").select { |f| f.match(%r{^(lib/|LICENSE|README)}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.8"
  spec.add_development_dependency 'coveralls', '~> 0'
end
