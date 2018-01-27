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


require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../../lib/armagh/standard_actions/publishers/excel_publish'
require_relative '../../../helpers/actions_test_helper'

class TestExcelPublish < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @excel_publish_action = instantiate_action(Armagh::StandardActions::ExcelPublish, mock('config'))

    source = mock('source')
    source.expects(:filename).at_least(0).returns('sample.xlsx')
    source.expects(:mtime).at_least(0).returns(Time.at(0))

    @doc = Armagh::Documents::ActionDocument.new(
      document_id: 123,
      title:       nil,
      copyright:   nil,
      content:     {},
      raw:         nil,
      metadata:    {},
      docspec:     nil,
      source:      source,
      document_timestamp: nil
    )

    @doc.stubs(:raw).once
  end

  def test_publish
    @excel_publish_action.stubs(:notify_ops).never
    @excel_publish_action.stubs(:notify_dev).never
    @excel_publish_action.stubs(:excel_to_text_and_display).once.returns(['text', 'display'])

    @excel_publish_action.publish(@doc)

    assert_equal 123, @doc.document_id
    assert_equal 'sample.xlsx', @doc.title
    assert_equal Time.at(0), @doc.document_timestamp
    assert_equal 'text', @doc.text
    assert_equal 'display', @doc.display
  end

  def test_publish_support_lib_error
    @excel_publish_action.stubs(:notify_ops).once
    @excel_publish_action.stubs(:notify_dev).never
    @excel_publish_action.stubs(:excel_to_text_and_display).raises(
      Armagh::Support::Excel::ExcelError, 'support library error'
    )

    @excel_publish_action.publish(@doc)

    assert_nil @doc.title
    assert_nil @doc.document_timestamp
    assert_nil @doc.text
    assert_nil @doc.display
  end

  def test_publish_unexpected_error
    @excel_publish_action.stubs(:notify_ops).never
    @excel_publish_action.stubs(:notify_dev).once
    @excel_publish_action.stubs(:excel_to_text_and_display).raises(
     RuntimeError, 'unexpected error'
    )

    @excel_publish_action.publish(@doc)

    assert_nil @doc.title
    assert_nil @doc.document_timestamp
    assert_nil @doc.text
    assert_nil @doc.display
  end

end
