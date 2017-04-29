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


require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../../lib/armagh/standard_actions/publishers/powerpoint_publish'
require_relative '../../../helpers/actions_test_helper'

class TestPowerPointPublish < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @powerpoint_publish_action = instantiate_action(Armagh::StandardActions::PowerPointPublish, mock('config'))

    content = {'bson_binary'=>mock('bson_binary')}
    content['bson_binary'].stubs(:data).once

    source = mock('source')
    source.expects(:filename).at_least(0).returns('sample.pptx')
    source.expects(:mtime).at_least(0).returns(Time.at(0))

    @doc = Armagh::Documents::ActionDocument.new(
      document_id: 123,
      title:       nil,
      copyright:   nil,
      content:     content,
      metadata:    {},
      docspec:     nil,
      source:      source,
      document_timestamp: nil
    )
  end

  def test_publish
    @powerpoint_publish_action.stubs(:notify_ops).never
    @powerpoint_publish_action.stubs(:notify_dev).never
    @powerpoint_publish_action.stubs(:powerpoint_to_text_and_display).once.returns(['text', 'display'])

    @powerpoint_publish_action.publish(@doc)

    assert_equal 123, @doc.document_id
    assert_equal 'sample.pptx', @doc.title
    assert_equal Time.at(0), @doc.document_timestamp
    assert_equal 'text', @doc.text
    assert_equal 'display', @doc.display
  end

  def test_publish_support_lib_error
    @powerpoint_publish_action.stubs(:notify_ops).once
    @powerpoint_publish_action.stubs(:notify_dev).never
    @powerpoint_publish_action.stubs(:powerpoint_to_text_and_display).raises(
      Armagh::Support::PowerPoint::PowerPointError, 'support library error'
    )

    @powerpoint_publish_action.publish(@doc)

    assert_nil @doc.title
    assert_nil @doc.document_timestamp
    assert_nil @doc.text
    assert_nil @doc.display
  end

  def test_publish_unexpected_error
    @powerpoint_publish_action.stubs(:notify_ops).never
    @powerpoint_publish_action.stubs(:notify_dev).once
    @powerpoint_publish_action.stubs(:powerpoint_to_text_and_display).raises(
      RuntimeError, 'unexpected error'
    )

    @powerpoint_publish_action.publish(@doc)

    assert_nil @doc.title
    assert_nil @doc.document_timestamp
    assert_nil @doc.text
    assert_nil @doc.display
  end

end
