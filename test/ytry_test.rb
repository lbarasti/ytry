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
  it 'should evaluate the given block and return itself on #each/#on_success, even if the block raises an error' do
    initial_value, current_value, toggle_value = new_flag()
    @success.each{|v| toggle_value.()}.must_equal @success
    current_value.().must_equal !initial_value
    @success.on_success{|v| toggle_value.()}.must_equal @success
    current_value.().must_equal initial_value
    @success.each{|v| fail}.must_equal @success
    @success.on_success{|v| fail}.must_equal @success
  end
  it 'should return itself and not evaluate the given block on #on_failure' do
    initial_value, current_value, toggle_value = new_flag()
    @success.on_failure{toggle_value.()}.must_equal @success
    current_value.().must_equal initial_value
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
  it 'should alias #flat_map with #collect_concat' do
    @success.method(:flat_map).must_equal @success.method(:collect_concat)
  end

  describe 'select/reject' do
    it 'should return the caller when the given block returns true/false respectively' do
      @success.select(&:even?).must_equal @success
      @success.reject(&:odd?).must_equal @success
    end
    it 'should return a Failure wrapping a RuntimeError when the given block returns false/true respectively' do
      assert Failure.new(RuntimeError) === @success.select(&:odd?)
      assert Failure.new(RuntimeError) === @success.reject(&:even?)
    end
    it 'should return a Failure when the given block raises one' do
      assert Failure.new(TypeError) === @success.select{ raise TypeError }
      assert Failure.new(TypeError) === @success.reject{ raise TypeError }
    end
  end

  it 'should return itself on `#recover`/`#or_else`' do
    @success.recover{fail}.must_equal @success
    @success.or_else{fail}.must_equal @success
  end
  it 'should return the wrapped value on `#get_or_else`' do
    @success.get_or_else{fail}.must_equal @success_value
  end

  describe '#grep' do
    it 'should be equivalent to a #select + #map combo' do
      @success.grep(-> x {x.even?}).must_equal @success
      @success.grep(-> x {x.odd?}).must_be_kind_of Failure
      @success.grep(@success_value){:ok}.must_equal Success.new(:ok)
      @success.grep(1..@success_value){:ok}.must_equal Success.new(:ok)
      @success.grep(1..@success_value){fail}.must_be_kind_of Failure
    end

    it 'should return a Failure wrapping any error raised while matching' do
      MatchingError = Class.new StandardError
      ->{ @success.grep(-> v { raise MatchingError }){ 42 }.get }.must_raise MatchingError
      ->{ @success.grep(-> v { raise MatchingError }){|v| raise TypeError}.get }.must_raise MatchingError
    end

    it 'should return a Failure when no match is found' do
      ->{ @success.grep(-> v { false }){ 42 }.get }.must_raise RuntimeError
      ->{ @success.grep(-> v { false }){ raise TypeError }.get }.must_raise RuntimeError
    end

    it 'should return a Failure wrapping any error raised while running the given block' do
      BlockError = Class.new StandardError
      ->{ @success.grep(-> v { true }){|v| raise BlockError }.get }.must_raise BlockError
    end

    it 'should return a Try when the block is omitted' do
      @success.grep(-> v { true }).must_equal @success
      @success.grep(-> v { false }).must_be_kind_of Failure
      assert Failure.new(RuntimeError) === @success.grep(-> v { false })
    end
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
  it 'should alias #flat_map with #collect_concat' do
    @failure.method(:flat_map).must_equal @failure.method(:collect_concat)
  end
  it 'should not evaluate the given block when calling enumerable methods' do
    initial_value, current_value, toggle_value = new_flag()
    @failure.each{|x| toggle_value.()}.must_equal @failure
    current_value.().must_equal initial_value
    @failure.any?{|x| toggle_value.(); x > 0}.must_equal false
    current_value.().must_equal initial_value
    @failure.all?{|x| toggle_value.(); x > 0}.must_equal true
    current_value.().must_equal initial_value
    @failure.include?(42).must_equal false
    @failure.reduce(42){toggle_value.(); raise RuntimeError}.must_equal 42
    @failure.each{|x| raise RuntimeError}.must_equal @failure
  end
  it 'should return itself and evaluate the given block on #on_failure' do
    initial_value, current_value, toggle_value = new_flag()
    @failure.on_failure{toggle_value.()}.must_equal @failure
    current_value.().must_equal !initial_value
  end
  it 'should return `other` on `#or_else`' do
    @failure.or_else {Try {1}}.get.must_equal 1
  end
  it 'should not raise an error to the caller if the given block raises one' do
    assert Failure.new(ArgumentError) === @failure.or_else { fail ArgumentError }
  end
  it 'should raise an error to the caller if the block does not return an instance of Try...' do
    -> { @failure.or_else { 1 } }.must_raise TypeError
  end
  it '... Even if the returned value is array-like' do
    -> { @failure.or_else { [1,2,3] } }.must_raise TypeError
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

  describe '#recover' do
    it 'turns a Failure into a Success when the given block evaluates with no errors' do
      @failure.recover{ 1 }.must_equal Success.new(1)
    end

    it "puts the error wrapped by the Failure in the block's scope for inspection" do
      @failure.recover{|e| e}.get.must_be_kind_of @failure_type
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
  end

  describe '#recover_with' do
    it 'is similar to #or_else...' do
      a_success = Success.new(0)
      other_failure = Failure.new(RuntimeError)
      @failure.recover_with{ other_failure }.must_equal other_failure
      @failure.recover_with{ a_success }.must_equal a_success
    end

    it '... but returns the caller when the block evaluates to nil - ' +
       'so that we can match on the desired errors in a concise fashion' do
      @failure.recover_with{ nil }.must_equal @failure

      a_success = Success.new(42)
      @failure.recover_with{|e| a_success if e.is_a?(RuntimeError)}
        .must_equal @failure

      @failure.recover_with{|e| a_success if e.is_a?(@failure_type)}
        .must_equal a_success

      @failure.recover_with{|e| case e
        when RuntimeError then a_success end
      }.must_equal @failure
    end

    it 'will raise a TypeError when the block does not evaluate to a Try' do
      -> { @failure.recover_with{ [1,2,3] } }.must_raise TypeError
      -> { @failure.recover_with{ false } }.must_raise TypeError
    end

    it 'should update the failure type when the recover_with block raises an error' do
      case @failure.recover_with{ raise RuntimeError }
        when @failure then fail
        when Failure.new(RuntimeError) then :ok
        else fail
      end
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