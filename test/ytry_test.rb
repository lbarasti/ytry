require_relative 'test_helper'

include Ytry

describe 'Ytry module' do
  it 'should have a version' do
    refute_nil ::Ytry::VERSION
  end
end

describe 'Try' do
  it 'should wrap a successful computation into Success' do
    Try{'hello'}.must_equal Success.new('hello')
  end
  it 'should wrap an exception into Failure when an exception is raised' do
    Try{raise TypeError}.must_be_kind_of Failure
  end
  describe '.zip' do
    before do
      @all_success = (1..5).map{|i| Try {i}}
      @some_failure = (1..5).map{|i| i%2 == 0 ? Try{i} : Try{fail RuntimeError.new(i)}}
    end
    it 'should return a Success wrapping all the zipped values when there are no Failures' do
      Try.zip(*@all_success).must_equal Success.new((1..5).to_a)
    end
    it 'should otherwise return the first Failure it finds in the given sequence of Trys' do
      Try.zip(*@some_failure).must_be_kind_of Failure
      Try.zip(*@some_failure).recover{|e| e}.get.message.must_equal "1"
    end
  end
end

describe 'Success' do
  before do
    @success = Try{ 41 + 1 }
    @success_value = @success.get
  end
  it 'should not support flattening a scalar value' do
    -> {@success.flatten}.must_raise TypeError
  end
  it 'should support `#flatten`/`#flat_map`' do
    Try{@success}.flatten.must_equal @success
    @success.map{|v| Try{v}}.flatten.must_equal @success
    @success.flat_map{|c| Try{c - 42}}.must_equal Try{0}
    @success.flat_map{|c| Try{raise TypeError}}.must_be_kind_of Failure
  end
  it 'should support flattening to the specified level' do
    triple_try = Try{Try{@success}}
    triple_try.flatten(-1).must_equal triple_try
    triple_try.flatten.get.must_equal @success
    triple_try.flatten(1).get.must_equal @success
    triple_try.flatten(2).must_equal @success
    -> { triple_try.flatten(3) }.must_raise TypeError
  end
  it 'should be forgiving when calling `#flat_map` on a Success wrapping a scalar value' do
    Try{1} | -> x {x/0}
    Try{1} | -> x {x}
  end
  it 'should return itself on `#recover`/`#or_else`' do
    @success.recover{fail}.must_equal @success
    @success.or_else{fail}.must_equal @success
  end
  it 'should return the wrapped value on `#get_or_else`' do
    @success.get_or_else{fail}.must_equal @success_value
  end
  it 'should support #grep' do
    @success.grep(-> x {x.even?}).must_equal @success
    @success.grep(-> x {x.odd?}).must_be_kind_of Failure
    @success.grep(@success_value){:ok}.must_equal Success.new(:ok)
    @success.grep(1..@success_value){:ok}.must_equal Success.new(:ok)
    @success.grep(1..@success_value){fail}.must_be_kind_of Failure
  end
  it 'should support #zip' do
    @success.zip(@success).must_equal Success.new([@success_value] * 2)
    @success.zip(Try{fail}).must_be_kind_of Failure
  end
end

describe 'Failure' do
  before do
    @failure = Try{ 1 / 0 }
    @failure_type = @failure.error.class
    @failure_message = @failure.error.inspect
  end
  it 'should raise an exception on #get' do
    -> { @failure.get }.must_raise ZeroDivisionError
  end
  it 'should return the wrapped exception on #error' do
    Try{raise TypeError}.error.must_be_kind_of TypeError
  end
  it 'should support case statements' do
    case @failure
      when Failure then :ok
      else fail
    end
    case @failure
      when Failure.new(@failure_type) then :ok
      else fail
    end
  end
  it 'should support `#map`/`#collect`/`#select`' do
    @failure.map{|v| v + 1}.must_equal @failure
    @failure.collect(&:succ).must_equal @failure
    @failure.select{|x| x < 0}.must_equal @failure
  end
  it 'should support `#flatten`/`#flat_map`' do
    @failure.flatten.must_equal @failure
    Try{@failure}.flatten(-1).get.must_equal @failure
    Try{@failure}.flatten.must_equal @failure
    Try{@failure}.flatten(1).must_equal @failure
    Try{@failure}.flatten(2).must_equal @failure
    Try{@failure}.flatten(3).must_equal @failure
    Try{@failure}.flat_map{|c| c}.must_equal @failure
  end
  it 'should be enumerable' do
    @failure.each{|x| raise RuntimeError}.must_equal @failure
    @failure.any?{|x| x > 0}.must_equal false
    @failure.all?{|x| x > 0}.must_equal true
    @failure.reduce(42){raise RuntimeError}.must_equal 42
    @failure.include?(42).must_equal false
  end
  it 'should return `other` on `#or_else`' do
    @failure.or_else {Try {1}}.get.must_equal 1
  end
  it 'should return `other` on `#get_or_else`' do
    @failure.get_or_else {'lazily evaluated'}.must_equal "lazily evaluated"
  end
  it 'does not support passing an argument to #get_or_else' do
    -> {@failure.get_or_else(42)}.must_raise ArgumentError
  end
  it 'should be empty' do
    @failure.empty?.must_equal true
  end
  it 'should have a nice string representation' do
    @failure.to_s.must_equal "Failure(#{@failure_message})"
  end
  it 'should be recoverable' do
    @failure.recover{|e| e}.get.must_be_kind_of @failure_type
    @failure.recover{|e| 1}.must_equal Success.new(1)
  end
  it 'should preserve the current error if the recover block returns nil' do
    @failure.recover{|e| case e; when RuntimeError then 1; end}.must_equal @failure
  end
  it 'should update the failure type when the recover block raises an error' do
    case @failure.recover{|e| raise RuntimeError}
      when Failure.new(@failure_type) then fail
      when Failure.new(RuntimeError) then :ok
      else fail
    end
  end
  it 'should always return itself on #grep' do
    @failure.grep(->{true}).must_equal @failure
  end
  it 'should always return itself on #zip' do
    @failure.zip(Try{:ok}).must_equal @failure
    @failure.zip(Try{fail}).must_equal @failure
  end
  it 'should behave predictably when combining #recover and #flatten' do
    nested_try = @failure.recover{|e| Try{raise RuntimeError}}
    case nested_try
      when Success.new(Failure.new(RuntimeError)) then :ok
      else fail
    end
    case nested_try.flatten
      when Failure.new(RuntimeError) then :ok
      else fail
    end
  end
end