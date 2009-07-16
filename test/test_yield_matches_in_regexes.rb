require File.join(File.dirname(__FILE__), "test_helper")

class TestYieldingMatches < Test::Unit::TestCase

  def test_fakeweb_accepting_procs_as_body
    assert_nothing_raised do
      FakeWeb.register_uri(:get, %r|http://example\.com/test_example/(\d+)|, :body => Proc.new{|a| a})
      response = Net::HTTP.start('example.com') { |query| query.get('/test_example/42') }
    end
  end

  def test_raise_error_when_sending_procs_and_not_regexes
    exception = assert_raise ArgumentError do # FIXME: Which exception should be thrown?
      FakeWeb.register_uri(:get, "http://example.com/test_example/", :body => Proc.new{|a| a})
    end
  end

  def test_yielded_matches_are_capture_groups
    expected_args = nil
    proc = Proc.new do |*yielded_args|
      expected_args = yielded_args
      yielded_args.join(', ')
    end
    FakeWeb.register_uri(:get, %r|http://example\.com/([^/]*)/(?:[^/]*)/([^/]*)|, :body => proc)
    response = Net::HTTP.start('example.com') { |query| query.get('/foo/bar/baz') }
    assert_equal 'foo, baz', response.body
    assert_equal ['foo', 'baz'], expected_args
  end

  def test_not_interferes_with_normal_response_bodies
    FakeWeb.register_uri(:get, %r|http://example.com/test_example/(\d+)|, :body => Proc.new{|a| a })
    FakeWeb.register_uri(:get, "http://example.com/test_example/string_body", :body => "String")
    FakeWeb.register_uri(:get, "http://example.com/test_example/regexp_body", :body => "Regexp")
    assert_equal '42', Net::HTTP.start('example.com') { |query| query.get('/test_example/42') }.body
    assert_equal 'String', Net::HTTP.start('example.com') { |query| query.get('/test_example/string_body') }.body
    assert_equal 'Regexp', Net::HTTP.start('example.com') { |query| query.get('/test_example/regexp_body') }.body
  end

end