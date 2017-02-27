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

require_relative '../../../lib/armagh/standard_actions/office_publish_action'
require_relative '../../helpers/actions_test_helper'

class TestOfficePublishAction < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @office_publish_action = instantiate_action(Armagh::StandardActions::OfficePublishAction, mock('config'))
    @office_publish_action.stubs(:notify_ops).never
    @office_publish_action.stubs(:notify_dev).never

    content = {'bson_binary'=>mock('bson_binary')}
    content['bson_binary'].stubs(:data).once
    @doc = {
      document_id: 0,
      title:       nil,
      copyright:   nil,
      content:     content,
      metadata:    {},
      docspec:     nil,
      source:      nil,
      document_timestamp: nil
    }
  end

  #
  # by file extension
  #

  def test_publish_excel
    @office_publish_action.stubs(:excel_to_text_and_display).once.returns(['text', 'display'])
    source = mock('source')
    source.stubs(filename: 'excel.xlsx',
                 mime_type: nil,
                 mtime: Time.at(0))
    doc = @doc.dup
    doc.merge!(document_id: 1,
               source: source)
    doc = Armagh::Documents::ActionDocument.new(doc)

    @office_publish_action.publish(doc)

    assert_equal 1, doc.document_id
    assert_equal source.filename, doc.title
    assert_equal source.mtime, doc.document_timestamp
    assert_equal 'text', doc.text
    assert_equal 'display', doc.display
    assert_equal 'Excel', doc.metadata['type']
  end

  def test_publish_pdf
    @office_publish_action.stubs(:pdf_to_text_and_display).once.returns(['text', 'display'])
    source = mock('source')
    source.stubs(filename: 'portable_document_format.pdf',
                 mime_type: nil,
                 mtime: Time.at(0))
    doc = @doc.dup
    doc.merge!(document_id: 2,
               source: source)
    doc = Armagh::Documents::ActionDocument.new(doc)

    @office_publish_action.publish(doc)

    assert_equal 2, doc.document_id
    assert_equal source.filename, doc.title
    assert_equal source.mtime, doc.document_timestamp
    assert_equal 'text', doc.text
    assert_equal 'display', doc.display
    assert_equal 'PDF', doc.metadata['type']
  end

  def test_publish_powerpoint
    @office_publish_action.stubs(:powerpoint_to_text_and_display).once.returns(['text', 'display'])
    source = mock('source')
    source.stubs(filename: 'powerpoint.pptm',
                 mime_type: nil,
                 mtime: Time.at(0))
    doc = @doc.dup
    doc.merge!(document_id: 3,
               source: source)
    doc = Armagh::Documents::ActionDocument.new(doc)

    @office_publish_action.publish(doc)

    assert_equal 3, doc.document_id
    assert_equal source.filename, doc.title
    assert_equal source.mtime, doc.document_timestamp
    assert_equal 'text', doc.text
    assert_equal 'display', doc.display
    assert_equal 'PowerPoint', doc.metadata['type']
  end

  def test_publish_word
    @office_publish_action.stubs(:word_to_text_and_display).once.returns(['text', 'display'])
    source = mock('source')
    source.stubs(filename: 'word.doc',
                 mime_type: nil,
                 mtime: Time.at(0))
    doc = @doc.dup
    doc.merge!(document_id: 4,
               source: source)
    doc = Armagh::Documents::ActionDocument.new(doc)

    @office_publish_action.publish(doc)

    assert_equal 4, doc.document_id
    assert_equal source.filename, doc.title
    assert_equal source.mtime, doc.document_timestamp
    assert_equal 'text', doc.text
    assert_equal 'display', doc.display
    assert_equal 'Word', doc.metadata['type']
  end

  def test_publish_unsupported_document
    @office_publish_action.stubs(:notify_ops).once
    source = mock('source')
    source.stubs(filename: 'unsupported.file',
                 mime_type: nil,
                 mtime: Time.at(0))
    doc = @doc.dup
    doc.merge!(document_id: 5,
               source: source)
    doc = Armagh::Documents::ActionDocument.new(doc)

    @office_publish_action.publish(doc)
  end

  def test_publish_unexpected_error
    @office_publish_action.stubs(:notify_dev).once
    @office_publish_action.stubs(:excel_to_text_and_display).raises(
     RuntimeError, 'unexpected error'
    )
    source = mock('source')
    source.stubs(filename: 'excel.xls',
                 mime_type: nil,
                 mtime: Time.at(0))
    doc = @doc.dup
    doc.merge!(document_id: 6,
               source: source)
    doc = Armagh::Documents::ActionDocument.new(doc)

    @office_publish_action.publish(doc)

    assert_nil doc.title
    assert_nil doc.document_timestamp
    assert_nil doc.text
    assert_nil doc.display
  end

  #
  # by mime type
  #

  def test_publish_mime_excel
    @office_publish_action.stubs(:excel_to_text_and_display).once.returns(['text', 'display'])
    source = mock('source')
    source.stubs(filename: nil,
                 mime_type: 'application/vnd.ms-excel',
                 mtime: Time.at(0))
    doc = @doc.dup
    doc.merge!(document_id: 7,
               source: source)
    doc = Armagh::Documents::ActionDocument.new(doc)

    @office_publish_action.publish(doc)

    assert_equal 7, doc.document_id
    assert_equal source.filename, doc.title
    assert_equal source.mtime, doc.document_timestamp
    assert_equal 'text', doc.text
    assert_equal 'display', doc.display
    assert_equal 'Excel', doc.metadata['type']
  end

  def test_publish_mime_pdf
    @office_publish_action.stubs(:pdf_to_text_and_display).once.returns(['text', 'display'])
    source = mock('source')
    source.stubs(filename: nil,
                 mime_type: 'application/pdf',
                 mtime: Time.at(0))
    doc = @doc.dup
    doc.merge!(document_id: 8,
               source: source)
    doc = Armagh::Documents::ActionDocument.new(doc)

    @office_publish_action.publish(doc)

    assert_equal 8, doc.document_id
    assert_equal source.filename, doc.title
    assert_equal source.mtime, doc.document_timestamp
    assert_equal 'text', doc.text
    assert_equal 'display', doc.display
    assert_equal 'PDF', doc.metadata['type']
  end

  def test_publish_mime_powerpoint
    @office_publish_action.stubs(:powerpoint_to_text_and_display).once.returns(['text', 'display'])
    source = mock('source')
    source.stubs(filename: nil,
                 mime_type: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
                 mtime: Time.at(0))
    doc = @doc.dup
    doc.merge!(document_id: 9,
               source: source)
    doc = Armagh::Documents::ActionDocument.new(doc)

    @office_publish_action.publish(doc)

    assert_equal 9, doc.document_id
    assert_equal source.filename, doc.title
    assert_equal source.mtime, doc.document_timestamp
    assert_equal 'text', doc.text
    assert_equal 'display', doc.display
    assert_equal 'PowerPoint', doc.metadata['type']
  end

  def test_publish_mime_word
    @office_publish_action.stubs(:word_to_text_and_display).once.returns(['text', 'display'])
    source = mock('source')
    source.stubs(filename: nil,
                 mime_type: 'application/vnd.ms-word.document.macroEnabled.12',
                 mtime: Time.at(0))
    doc = @doc.dup
    doc.merge!(document_id: 10,
               source: source)
    doc = Armagh::Documents::ActionDocument.new(doc)

    @office_publish_action.publish(doc)

    assert_equal 10, doc.document_id
    assert_equal source.filename, doc.title
    assert_equal source.mtime, doc.document_timestamp
    assert_equal 'text', doc.text
    assert_equal 'display', doc.display
    assert_equal 'Word', doc.metadata['type']
  end

  def test_publish_mime_unsupported_document
    source = mock('source')
    source.stubs(filename: nil,
                 mime_type: 'unsupported-mime-type',
                 mtime: Time.at(0))
    doc = @doc.dup
    doc.merge!(document_id: 11,
               source: source)
    doc = Armagh::Documents::ActionDocument.new(doc)

    @office_publish_action.stubs(:notify_ops).once
    @office_publish_action.publish(doc)
  end

end
