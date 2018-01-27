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

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../../lib/armagh/standard_actions/publishers/html_publish'
require_relative '../../../helpers/actions_test_helper'

class TestHTMLPublish < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @html_publish_action = instantiate_action(Armagh::StandardActions::HTMLPublish, mock('config'))

    source = mock('source')
    @url = 'http://sample.url'
    source.stubs(filename: nil, url: @url)

    @doc = Armagh::Documents::ActionDocument.new(
      document_id: nil,
      title:       nil,
      copyright:   nil,
      content:     {},
      raw:         nil,
      metadata:    {},
      docspec:     nil,
      source:      source,
      document_timestamp: Time.now
    )

    @doc.raw = 'Some Document Content'
  end

  def test_publish
    @html_publish_action.stubs(:notify_ops).never
    @html_publish_action.stubs(:notify_dev).never
    @html_publish_action.stubs(:html_to_text).once.returns('text')

    @html_publish_action.publish(@doc)

    assert_equal @url, @doc.title
    assert_equal "text\n\nOriginal Content: #{@url}", @doc.text
  end

  def test_publish_no_url
    @html_publish_action.stubs(:notify_ops).never
    @html_publish_action.stubs(:notify_dev).never
    @html_publish_action.stubs(:html_to_text).once.returns('text')

    @doc.source.stubs(:url).returns(nil)

    @html_publish_action.publish(@doc)

    assert_nil @doc.title
    assert_equal 'text', @doc.text
  end


  def test_publish_support_lib_error
    @html_publish_action.stubs(:notify_ops).once
    @html_publish_action.stubs(:notify_dev).never
    @html_publish_action.stubs(:html_to_text).once.raises(
      Armagh::Support::HTML::HTMLError, 'support library error'
    )

    @html_publish_action.publish(@doc)

    assert_nil @doc.title
    assert_nil @doc.text
  end

  def test_publish_unexpected_error
    @html_publish_action.stubs(:notify_ops).never
    @html_publish_action.stubs(:notify_dev).once
    @html_publish_action.stubs(:html_to_text).once.raises(
      RuntimeError, 'unexpected error'
    )

    @html_publish_action.publish(@doc)

    assert_nil @doc.title
    assert_nil @doc.text
  end

  def test_publish_multiple_pages
    @doc.raw = ['Page One', 'Page Two'].join(Armagh::Support::HTML::HTML_PAGE_DELIMITER)

    @html_publish_action.stubs(:notify_ops).never
    @html_publish_action.stubs(:notify_dev).never
    @html_publish_action.stubs(:html_to_text).twice.returns('text')

    @html_publish_action.publish(@doc)

    assert_equal 'http://sample.url', @doc.title
    assert_equal "text\n\n--- PAGE 2 ---\n\ntext\n\nOriginal Content: #{@url}", @doc.text
  end

end
