# Copyright 2018 Noragh Analytics, Inc.
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

require_relative '../../../helpers/coverage_helper'
require_relative '../../../helpers/actions_test_helper'

require 'test/unit'
require 'mocha/test_unit'
require 'webmock/test_unit'

require_relative '../../../../lib/armagh/standard_actions/collectors/rss_collect'

class TestRSSCollect < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @docspec_name = 'docspec'
    @config_values = {
      'action' => {
        'name' => 'collect_me',
        'active' => true,
        'workflow' => 'wf'
      },
      'output' => {
        @docspec_name => Armagh::Documents::DocSpec.new('OutputDocument', Armagh::Documents::DocState::READY)
      },
      'collect' => {
        'schedule' => '0 * * * *',
        'archive' => false
      },
      'http' => {
        'url' => 'http://test.url',
        'headers' => {}
      },
      'rss' => {}
    }
    @config = Armagh::StandardActions::RSSCollect.create_configuration([], 'test', @config_values)
    @rss_collect_action = instantiate_action(Armagh::StandardActions::RSSCollect, @config)
  end

  def test_collect
    expected_id = 'kRAt5JjnOEeuDonOLcC0Aw'
    expected_title = 'Title'
    expected_content = 'Expected content'
    channel_details = {'title' => 'CHANNEL_TITLE'}
    item_details = {'title' => expected_title, 'guid' => 'some_guid'}
    type_details = {'type' => 'text/html', 'encoding' => 'utf-8'}
    doc_time = Time.utc(100)
    expected_source = Armagh::Documents::Source.new(encoding: type_details['encoding'], mime_type: type_details['type'], type: 'url', url: @config_values['http']['url'], mtime: doc_time)
    expected_meta = {'rss_url' => @config.http.url}
    state = mock
    @rss_collect_action.expects(:with_locked_action_state).yields(state)
    assert_create(@rss_collect_action) do |document_id, title, copyright, document_timestamp, collected, metadata, docspec_name, source|
      assert_equal(expected_id, document_id)
      assert_equal(expected_title, title)
      assert_nil copyright
      assert_equal(doc_time, document_timestamp)
      assert_equal expected_content, collected
      assert_true(metadata.has_key?('collected_timestamp'))
      metadata.delete('collected_timestamp')
      assert_equal expected_meta, metadata
      assert_equal(expected_source.to_hash, source.to_hash)
    end
    @rss_collect_action.stubs(:collect_rss).yields(channel_details, item_details, [expected_content], type_details, doc_time, nil)
    @rss_collect_action.collect
  end

  def test_collect_with_html_escaped_links
    @config_values['rss']['link_field'] = 'link'
    @config = Armagh::StandardActions::RSSCollect.create_configuration([], 'test', @config_values)
    @rss_collect_action = instantiate_action(Armagh::StandardActions::RSSCollect, @config)
    html_escaped_link = 'http://www2c.cdc.gov/podcasts/download.asp?af=h&amp;f=8645217'
    clean_link = "http://www2c.cdc.gov/podcasts/download.asp?af=h&f=8645217"
    expected_title = 'Title'
    expected_content = 'Expected content'
    channel_details = {'title' => 'CHANNEL_TITLE'}
    item_details = {'title' => expected_title, 'guid' => 'some_guid', 'link' => html_escaped_link}
    type_details = {'type' => 'text/html', 'encoding' => 'utf-8'}
    doc_time = Time.utc(100)
    expected_source = Armagh::Documents::Source.new(encoding: type_details['encoding'], mime_type: type_details['type'], type: 'url', url: clean_link, mtime: doc_time)
    state = mock
    @rss_collect_action.expects(:with_locked_action_state).yields(state)
    assert_create(@rss_collect_action) do |document_id, title, copyright, document_timestamp, collected, metadata, docspec_name, source|
      assert_equal(expected_source.to_hash, source.to_hash)
    end
    @rss_collect_action.stubs(:collect_rss).yields(channel_details, item_details, [expected_content], type_details, doc_time, nil)
    @rss_collect_action.collect
  end

  def test_collect_without_guid_uses_id
    channel_details = {'title' => 'CHANNEL_TITLE'}
    item_details = {
      'title' => 'Research Blog',
      'id' => 'http://www.somewebsite.com/blog/research/2017/01/some_link.html'
    }
    expected_contents = 'research articles'
    type_details = {'type' => 'text/html', 'encoding' => 'utf-8'}
    doc_time = Time.utc(100)
    state = mock
    @rss_collect_action.expects(:with_locked_action_state).yields(state)
    assert_create(@rss_collect_action) do |document_id, title, copyright, document_timestamp, collected, metadata, docspec_name, source|
      assert_equal 'e8aAA44qU6VgZJ4pqbfSrg', document_id
    end
    @rss_collect_action.stubs(:collect_rss).yields(channel_details, item_details, [expected_contents], type_details, doc_time, nil)
    @rss_collect_action.collect
  end

  def test_collect_without_guid_or_id_uses_link
    channel_details = {'title' => 'CHANNEL_TITLE'}
    item_details = {
      'link' => 'http://www.ncaa.com/news'
    }
    expected_contents = 'research articles'
    type_details = {'type' => 'text/html', 'encoding' => 'utf-8'}
    doc_time = Time.utc(100)
    state = mock
    @rss_collect_action.expects(:with_locked_action_state).yields(state)
    assert_create(@rss_collect_action) do |document_id, title, copyright, document_timestamp, collected, metadata, docspec_name, source|
      assert_equal 'cyNZ83wVQ2bOuonghkQEkg', document_id
    end
    @rss_collect_action.stubs(:collect_rss).yields(channel_details, item_details, [expected_contents], type_details, doc_time, nil)
    @rss_collect_action.collect
  end

  def test_collect_with_empty_guid_uses_id
    channel_details = {'title' => 'CHANNEL_TITLE'}
    item_details = {
      'guid' => '',
      'id' => 'http://www.somewebsite.com/blog/research/2017/01/some_link.html'
    }
    expected_contents = 'research articles'
    type_details = {'type' => 'text/html', 'encoding' => 'utf-8'}
    doc_time = Time.utc(100)
    state = mock
    @rss_collect_action.expects(:with_locked_action_state).yields(state)
    assert_create(@rss_collect_action) do |document_id, title, copyright, document_timestamp, collected, metadata, docspec_name, source|
      assert_equal 'e8aAA44qU6VgZJ4pqbfSrg', document_id
    end
    @rss_collect_action.stubs(:collect_rss).yields(channel_details, item_details, [expected_contents], type_details, doc_time, nil)
    @rss_collect_action.collect
  end

  def test_collect_without_guid_id_link_title
    channel_details = {'title' => 'CHANNEL_TITLE'}
    item_details = {
      'some_key' => 'some_value'
    }
    expected_contents = 'research articles'
    type_details = {'type' => 'text/html', 'encoding' => 'utf-8'}
    doc_time = Time.utc(100)
    state = mock
    @rss_collect_action.expects(:with_locked_action_state).yields(state)
    assert_create(@rss_collect_action) do |document_id, title, copyright, document_timestamp, collected, metadata, docspec_name, source|
    end
    @rss_collect_action.stubs(:collect_rss).yields(channel_details, item_details, [expected_contents], type_details, doc_time, nil)
    assert_notify_ops(@rss_collect_action) do |e|
      assert_equal "Document does not contain a 'guid', 'id', 'link' or 'title' fields", e
    end
    @rss_collect_action.collect
  end

  def test_collect_passthrough
    @config_values['rss']['passthrough'] = true
    @config = Armagh::StandardActions::RSSCollect.create_configuration([], 'test', @config_values)
    @rss_collect_action = instantiate_action(Armagh::StandardActions::RSSCollect, @config)

    expected_content = 'Expected content'
    channel_details = {'title' => 'CHANNEL_TITLE'}
    item_details = {'title' => 'TITLE'}
    type_details = {'type' => 'text/html', 'encoding' => 'utf-8'}
    doc_time = Time.utc(100)
    expected_source = Armagh::Documents::Source.new(encoding: type_details['encoding'], mime_type: type_details['type'], type: 'url', url: @config_values['http']['url'], mtime: doc_time)

    expected_meta = {'rss_url' => @config.http.url, 'item' => item_details, 'channel' => channel_details}

    state = mock
    @rss_collect_action.expects(:with_locked_action_state).yields(state)

    assert_create(@rss_collect_action) do |document_id, title, copyright, document_timestamp, collected, metadata, docspec_name, source|
      assert_nil document_id
      assert_nil title
      assert_nil copyright
      assert_nil document_timestamp
      assert_equal expected_content, collected
      assert_true(metadata.has_key?('collected_timestamp'))
      metadata.delete('collected_timestamp')
      assert_equal expected_meta, metadata
      assert_equal(expected_source.to_hash, source.to_hash)
    end

    @rss_collect_action.stubs(:collect_rss).yields(channel_details, item_details, [expected_content], type_details, doc_time, nil)
    @rss_collect_action.collect
  end

  def test_collect_item_rss_error
    exception = Armagh::Support::RSS::RSSError.new 'Error'

    state = mock
    @rss_collect_action.expects(:with_locked_action_state).yields(state)

    @rss_collect_action.stubs(:collect_rss).yields({}, {}, {}, {}, {}, exception)
    assert_notify_ops(@rss_collect_action) do |e|
      assert_equal e, exception
    end

    @rss_collect_action.collect
  end

  def test_collect_item_http_error
    exception = Armagh::Support::HTTP::HTTPError.new 'Error'

    state = mock
    @rss_collect_action.expects(:with_locked_action_state).yields(state)

    @rss_collect_action.stubs(:collect_rss).yields({}, {}, {}, {}, {}, exception)
    assert_notify_ops(@rss_collect_action) do |e|
      assert_equal e, exception
    end

    @rss_collect_action.collect
  end

  def test_collect_item_unknown_error
    exception = RuntimeError.new 'Error'

    state = mock
    @rss_collect_action.expects(:with_locked_action_state).yields(state)

    @rss_collect_action.stubs(:collect_rss).yields({}, {}, {}, {}, {}, exception)
    assert_notify_dev(@rss_collect_action) do |e|
      assert_equal e, exception
    end

    @rss_collect_action.collect
  end

  def test_collect_failure
    exception = Armagh::Support::RSS::RSSError.new 'Error'

    state = mock
    @rss_collect_action.expects(:with_locked_action_state).yields(state)

    @rss_collect_action.stubs(:collect_rss).raises(exception)
    assert_notify_ops(@rss_collect_action) do |e|
      assert_equal e, exception
    end

    @rss_collect_action.collect
  end

  def test_collect_multiple_pages
    state = mock
    @rss_collect_action.expects(:with_locked_action_state).yields(state)

    assert_create(@rss_collect_action) do |document_id, title, copyright, document_timestamp, collected, metadata, docspec_name, source|
      assert_equal 'ONE*#Y*@^~YUTWO*#Y*@^~YUTHREE', collected
    end

    @rss_collect_action.stubs(:collect_rss).yields({}, {"title"=>"some title", "guid"=>"some_guid"}, %w(ONE TWO THREE), {}, Time.now, nil)
    @rss_collect_action.collect
  end
end
