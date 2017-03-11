# Copyright 2017 Noragh Analytics, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative '../../helpers/coverage_helper'
require_relative '../../helpers/actions_test_helper'

require 'test/unit'
require 'mocha/test_unit'
require 'webmock/test_unit'

require_relative '../../../lib/armagh/standard_actions/http_collect_action'

class TestHTTPCollectAction < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @config_values = {
      'output' => {
        'http_collected_document' => Armagh::Documents::DocSpec.new('OutputDocument', Armagh::Documents::DocState::READY)
      },
      'collect' => {
        'schedule' => '0 * * * *',
        'archive' => false
      },
      'http' => {
        'url' => 'http://test.url',
        'follow_redirects' => true,
        'headers' => {}
      }
    }
    @config = Armagh::StandardActions::HTTPCollectAction.create_configuration( [], 'test', @config_values )
    @http_collect_action = instantiate_action(Armagh::StandardActions::HTTPCollectAction, @config )

    @state = mock
  end

  def test_collect
    @state.stubs(:content).returns({})
    @http_collect_action.expects(:with_locked_action_state).yields(@state)

    expected_body = 'response body'
    expected_meta = {
        'url' => @config.http.url
    }
    expected_source = Armagh::Documents::Source.new(type: 'url',
                                                    url: @config.http.url,
                                                    mime_type: 'text/html',
                                                    encoding: 'ISO-8859-1')

    stub_request(:get, @config.http.url).to_return(body: expected_body, headers: {'Content-Type' => 'text/html; charset=ISO-8859-1'})

    assert_create(@http_collect_action) do |document_id, title, copyright, document_timestamp, body, meta, docspec_name, source|
      assert_equal expected_body, body
      meta.delete('collected_timestamp')
      assert_equal expected_meta, meta
      assert_not_nil @config.output.http_collected_document
      assert_equal expected_source, source
    end
    @http_collect_action.collect
  end

  def test_collect_no_encoding
    @state.stubs(:content).returns({})
    @http_collect_action.expects(:with_locked_action_state).yields(@state)

    expected_body = 'response body'
    expected_meta = {
        'url' => @config.http.url,
    }

    expected_source = Armagh::Documents::Source.new(type: 'url', url: @config.http.url, mime_type: 'text/html')

    stub_request(:get, @config.http.url).to_return(body: expected_body, headers: {'Content-Type' => 'text/html'})
    assert_create(@http_collect_action) do |document_id, title, copyright, document_timestamp, body, meta, docspec_name, source|
      assert_equal expected_body, body
      meta.delete('collected_timestamp')
      assert_equal expected_meta, meta
      assert_not_nil @config.output.http_collected_document
      assert_equal expected_source, source
      true
    end
    @http_collect_action.collect
  end

  def test_collect_no_type
    @state.stubs(:content).returns({})
    @http_collect_action.expects(:with_locked_action_state).yields(@state)

    expected_body = 'response body'
    expected_meta = {
        'url' => @config.http.url,
    }

    expected_source = Armagh::Documents::Source.new(type: 'url', url: @config.http.url)

    stub_request(:get, @config.http.url).to_return(body: expected_body, headers: {'Content-Type' => nil})
    assert_create(@http_collect_action) do |document_id, title, copyright, document_timestamp, body, meta, docspec_name, source|
      assert_equal expected_body, body
      meta.delete('collected_timestamp')
      assert_equal expected_meta, meta
      assert_not_nil @config.output.http_collected_document
      assert_equal expected_source, source
      true
    end
    @http_collect_action.collect
  end

  def test_collect_http_error
    exception = Armagh::Support::HTTP::HTTPError.new('HTTP ERROR')
    Armagh::Support::HTTP::Connection.any_instance.expects(:fetch).raises(exception)

    assert_notify_ops(@http_collect_action) do |e|
      assert_equal exception, e
    end

    @http_collect_action.collect
  end

  def test_collect_config_http_error
    @config_values['http']['url']= 'bad url'
    e = assert_raise( Configh::ConfigInitError ) do
      @config = Armagh::StandardActions::HTTPCollectAction.create_configuration( [], 'test2', @config_values )
    end
    assert_equal "Unable to create configuration Armagh::StandardActions::HTTPCollectAction test2: 'bad url' is not a valid HTTP or HTTPS URL.", e.message
  end

  def test_collect_unknown_error
    e = RuntimeError.new('Unexpected error')
    Armagh::Support::HTTP::Connection.any_instance.expects(:fetch).raises(e)
    assert_raise(e) {@http_collect_action.collect}
  end

  def test_collect_multiple_pages
    @state.stubs(:content).returns({})
    @http_collect_action.expects(:with_locked_action_state).yields(@state)

    Armagh::Support::HTTP::Connection.any_instance.expects(:fetch).returns([{'head' => '', 'body' => 'BODY ONE'},
                                                                            {'head' => '', 'body' => 'BODY TWO'},
                                                                            {'head' => '', 'body' => 'BODY THREE'}])

    assert_create(@http_collect_action) do |document_id, title, copyright, document_timestamp, body, meta, docspec_name, source|
      assert_equal('BODY ONE*#Y*@^~YUBODY TWO*#Y*@^~YUBODY THREE', body)
    end

    @http_collect_action.collect
  end

  def test_collect_already_collected
    @config_values['http_collect_action'] = {'deduplicate_content' => true}
    @config = Armagh::StandardActions::HTTPCollectAction.create_configuration( [], 'test', @config_values )
    @http_collect_action = instantiate_action(Armagh::StandardActions::HTTPCollectAction, @config )

    expected_body = 'response body'
    md5 = Armagh::Support::StringDigest.md5(expected_body)

    @state.stubs(:content).returns({@config.http.url => md5})
    @http_collect_action.expects(:with_locked_action_state).yields(@state)
    @http_collect_action.expects(:create).never

    stub_request(:get, @config.http.url).to_return(body: expected_body, headers: {'Content-Type' => 'text/html; charset=ISO-8859-1'})

    @http_collect_action.collect
  end

  def test_collect_changed_collected
    @config_values['http_collect_action'] = {'deduplicate_content' => true}
    @config = Armagh::StandardActions::HTTPCollectAction.create_configuration( [], 'test', @config_values )
    @http_collect_action = instantiate_action(Armagh::StandardActions::HTTPCollectAction, @config )

    expected_body = 'response body'
    md5 = Armagh::Support::StringDigest.md5('Old Content')

    @state.stubs(:content).returns({@config.http.url => md5})
    @http_collect_action.expects(:with_locked_action_state).yields(@state)

    stub_request(:get, @config.http.url).to_return(body: expected_body, headers: {'Content-Type' => 'text/html; charset=ISO-8859-1'})

    assert_create(@http_collect_action) do |document_id, title, copyright, document_timestamp, body, meta, docspec_name, source|
      assert_equal(expected_body, body)
    end

    @http_collect_action.collect
  end
end
