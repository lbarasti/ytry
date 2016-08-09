require_relative 'test_helper'

include Ytry

# The following tests are a port of TryTests.scala @ scala-2.11.8/test/files/jvm/future-spec/TryTests.scala
describe "Try" do
  MyError = Class.new StandardError

  let(:error) { RuntimeError.new("TestError") }
  
  describe "Try{}" do
    it "catch exceptions and lift into the Try type" do
      Try{ 1 }.must_equal Success.new(1)
      Try{ raise error }.must_equal Failure.new(error)
    end
  end

  it "recover_with" do
    other_error = MyError.new
    Success.new(1).recover_with { Success.new(2) }.must_equal Success.new(1)
    Failure.new(error).recover_with { Success.new(2) }.must_equal Success.new(2)
    Failure.new(error).recover_with { Failure.new(other_error) }.must_equal Failure.new(other_error)
  end

  it "get_or_else" do
    Success.new(1).get_or_else{2}.must_equal 1
    Failure.new(error).get_or_else{2}.must_equal 2
  end

  it "or_else" do
    Success.new(1).or_else{ Success.new(2) }.must_equal Success.new(1)
    Failure.new(error).or_else{ Success.new(2) }.must_equal Success.new(2)
  end

  describe "map" do
    it "when there is no exception" do
      Success.new(1).map(&:succ).must_equal Success.new(2)
      Failure.new(error).map(&:succ).must_equal Failure.new(error)
    end

    it "when there is an exception" do
      Success.new(1).map{raise error}.must_equal Failure.new(error)

      other_error = MyError.new
      Failure.new(error).map{raise other_error}.must_equal Failure.new(error)
    end
    it "when there is a fatal exception" do
      -> {Success.new(1).map{raise SecurityError}}
        .must_raise SecurityError
    end
  end

  describe "flat_map" do
    it "when there is no exception" do
      Success.new(1).flat_map{|v| Success.new(v + 1)}.must_equal Success.new(2)
      Failure.new(error).flat_map{|v| Success.new(v + 1)}.must_equal Failure.new(error)
    end

    it "when there is an exception" do
      Success.new(1).flat_map{raise error}.must_equal Failure.new(error)

      other_error = MyError.new
      Failure.new(error).flat_map{raise other_error}.must_equal Failure.new(error)
    end
    it "when there is a fatal exception" do
      -> {Success.new(1).flat_map{raise SecurityError}}
        .must_raise SecurityError
    end
  end

  describe "flatten" do
    it "is a Success(Success)" do
      Success.new(Success.new(1)).flatten.must_equal Success.new(1)
    end

    it "is a Success(Failure)" do
      Success.new(Failure.new(error))
        .flatten.must_equal Failure.new(error)
    end

    it "is a Failure" do
      Failure.new(error).flatten.must_equal Failure.new(error)
    end
  end

  # analogous to scala for-comprehension
  describe "flat_map + map" do
    it "returns Success when there are no failures" do
      a = Success.new(1)
      b = Success.new(2)

      a.flat_map{|va| b.map{|vb| va + vb}}.must_equal Success.new(3)
    end

    it "returns Failure when one of the callers is a failure" do
      a = Failure.new(error)
      b = Success.new(2)

      a.flat_map{|va| b.map{|vb| va + vb}}.must_equal Failure.new(error)
      b.flat_map{|vb| a.map{|va| vb + va}}.must_equal Failure.new(error)
    end

    it "returns the first occurring failure when there are multiple failures among the callers" do
      a = Failure.new(error)
      other_error = MyError.new 
      b = Failure.new(other_error)

      a.flat_map{|va| b.map{|vb| va + vb}}.must_equal Failure.new(error)
      b.flat_map{|vb| a.map{|va| vb + va}}.must_equal Failure.new(other_error)
    end
  end
  
end