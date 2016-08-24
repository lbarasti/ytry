require 'ytry/version'

module Ytry
  def Try
    raise ArgumentError, 'missing block' unless block_given?
    begin
      Success.new(yield)
    rescue StandardError => e
      Failure.new(e)
    end
  end
  module Try
    include Enumerable
    def self.ary_to_type value
      raise Try.invalid_argument('Argument must be an array-like object', value) unless value.respond_to? :to_ary
      return value if value.is_a? Try
      value.to_ary.empty? ?
        Failure.new(RuntimeError.new("Element not found").tap{|ex| ex.set_backtrace(caller)}) :
        Success.new(value.to_ary.first)
    end
    def self.zip *try_array
      first_failure = try_array.find(&:empty?)
      first_failure.nil? ? Success.new(try_array.map(&:get)) : first_failure
    end
    def each
      return enum_for(__method__) unless block_given?
      Try { yield self.get unless empty? }
      return self
    end
    alias_method :on_success, :each
    def on_failure
      return enum_for(__method__) unless block_given?
      return self
    end
    def map &block
      block or return enum_for(__method__)
      self.empty? ? self : Try{block.call(self.get)}
    end
    alias_method :collect, :map
    def select &block
      block or return enum_for(__method__)
      return self if empty?
      predicate = Try{ block.call(self.get) }
      return predicate if predicate.empty?
      predicate.get ? self : Try.ary_to_type([])
    end
    def reject &block
      if block_given? then select {|v| ! block.call(v)}
      else enum_for(__method__)
      end
    end
    def flat_map &block
      block or return enum_for(method)
      return self if self.empty?
      wrapped_result = Try{block.call(self.get)}
      return wrapped_result if (!wrapped_result.empty? && !wrapped_result.get.respond_to?(:to_ary))
      Try.ary_to_type(wrapped_result.flatten)
    end
    alias_method :collect_concat, :flat_map
    def grep pattern
      return self if self.empty?
      match = Try {
        (pattern === self.get) ? self.get : (raise RuntimeError.new("Element not found"))
      }
      block_given? ? match.map{|v| yield v} : match
    end
    def flatten level = 1
      level.times.reduce(self) { |current, _|
        break(current) if current.empty?
        Try.ary_to_type current.get
      }
    end
    def zip *others
      Try.zip(self, *others)
    end
    def | lambda
      self.flat_map &lambda # slow but easy to read + supports symbols out of the box
    end
    def or_else
      return self unless empty?
      other = yield
      other.is_a?(Try) ? other : raise(Try.invalid_argument('Block should evaluate to an instance of Try', other))
    end
    def get_or_else
      raise ArgumentError, 'missing block' unless block_given?
      return self.get unless empty?
      yield
    end
    def inspect() to_s end
    private
    def self.invalid_argument type_str, arg
      TypeError.new "#{type_str}. Found #{arg.class}"
    end
  end
  class Success
    include Try
    def initialize value
      @value = value.freeze
    end
    def get() @value end
    def empty?() false end
    def to_s() "Success(#{get})" end
    def to_ary() [get] end
    def == other
      other.is_a?(Success) && self.get == other.get
    end
    def === other
      other.is_a?(Success) && self.get === other.get
    end
    def recover &block
      raise ArgumentError, 'missing block' unless block_given?
      self
    end
    def recover_with &block
      raise ArgumentError, 'missing block' unless block_given?
      self
    end
  end
  class Failure
    include Try
    attr_reader :error
    def initialize value
      @error = value.freeze
    end
    def get() raise @error end
    def empty?() true end
    def to_s() "Failure(#{@error.inspect})" end
    def to_ary() [] end
    def == other
      other.is_a?(Failure) && self.error == other.error
    end
    def === other
      other.is_a?(Failure) && self.error === other.error
    end
    def on_failure
      return enum_for(__method__) unless block_given?
      Try { yield @error }
      return self
    end
    def recover &block
      raise ArgumentError, 'missing block' unless block_given?
      candidate = Success.new(@error).map &block
      (!candidate.empty? && candidate.get.nil?) ? self : candidate
    end
    def recover_with &block
      candidate = self.recover(&block)
      if (!candidate.empty? && !candidate.get.is_a?(Try))
        raise(Try.invalid_argument('Block should evaluate to an instance of Try', candidate.get))
      else
        candidate.flatten
      end
    end
  end
end