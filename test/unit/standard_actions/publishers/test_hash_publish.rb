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

require_relative '../../../../lib/armagh/standard_actions/publishers/hash_publish'

class TestHashPublish < Test::Unit::TestCase

  def setup
    @now       = Time.now
    @yesterday = @now - 1 * 24 * 60 * 60
    @last_week = @now - 7 * 24 * 60 * 60

    @logger = mock
    @caller = mock
    @collection = mock
    @raw = ''
    @metadata = {
      'copyright' => 'Metadata copyright notice'
    },
    @source = stub('source', 'filename' => "source_file.csv",
                             'mtime'     => @last_week,
                  )
    @draft_docspec = Armagh::Documents::DocSpec.new('doctype', Armagh::Documents::DocState::PUBLISHED)

    @doc = Armagh::Documents::ActionDocument.new(
      document_id:        'Orig id',
      content:            'Orig content',
      raw:                @raw,
      metadata:           @metadata,
      docspec:            @draft_docspec,
      source:             @source,
      title:              'Orig title',
      copyright:          'Orig copyright',
      document_timestamp: @now,
    )
  end

  def test_when_content_is_nested_publish_sets_document_attributes
    config_values = {
        'action' => { 'workflow' => 'wf'},
      'input'  => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::READY ) },
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::PUBLISHED) },
      'field_map' => {
        'get_doc_id_from'        => '["account", "account_number"]',
        'get_doc_title_from'     => '["title"]',
        'get_doc_timestamp_from' => '["timestamp"]',
        'get_doc_copyright_from' => '["copyright"]',
      }
    }

    content = {
      'account' => {
        'account_number' => '101',
        'name'           => 'Brian',
        'email'          => 'brian@example.com',
        'phone'          => '555-1212',
      },
      'timestamp'      => @yesterday,
      'copyright'      => "Copyright (c) 2016",
      'title'          => "New Title"
    }

    config       = Armagh::StandardActions::HashPublish.create_configuration( [], 'hash_test', config_values )
    hash_publish = Armagh::StandardActions::HashPublish.new(@caller, @logger, config)

    doc = @doc.dup
    doc.content = content

    assert_not_equal '101',                doc.document_id,        'pre-condition'
    assert_not_equal "New Title",          doc.title,              'pre-condition'
    assert_not_equal "Copyright (c) 2016", doc.copyright,          'pre-condition'
    assert_not_equal @yesterday,           doc.document_timestamp, 'pre-condition'

    hash_publish.publish(doc)

    assert_equal '101',                doc.document_id
    assert_equal "New Title",          doc.title
    assert_equal "Copyright (c) 2016", doc.copyright
    assert_equal @yesterday,           doc.document_timestamp
  end

  def test_when_content_is_not_nested_publish_sets_document_attributes
    config_values = {
        'action' => { 'workflow' => 'wf'},
      'input'  => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::READY ) },
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::PUBLISHED) },
      'field_map' => {
        'get_doc_id_from'        => '["account_number"]',
        'get_doc_title_from'     => '["title"]',
        'get_doc_timestamp_from' => '["timestamp"]',
        'get_doc_copyright_from' => '["copyright"]',
      }
    }

    content = {
      'account_number' => '101',
      'name'           => 'Brian',
      'email'          => 'brian@example.com',
      'phone'          => '555-1212',
      'timestamp'      => @yesterday,
      'copyright'      => "Copyright (c) 2016",
      'title'          => "New Title"
    }

    config = Armagh::StandardActions::HashPublish.create_configuration( [], 'hash_test', config_values )
    hash_publish = Armagh::StandardActions::HashPublish.new(@caller, @logger, config)

    doc = @doc.dup
    doc.content = content

    assert_not_equal '101',                doc.document_id,        'pre-condition'
    assert_not_equal "New Title",          doc.title,              'pre-condition'
    assert_not_equal "Copyright (c) 2016", doc.copyright,          'pre-condition'
    assert_not_equal @yesterday,           doc.document_timestamp, 'pre-condition'

    hash_publish.publish(doc)

    assert_equal '101',                doc.document_id
    assert_equal "New Title",          doc.title
    assert_equal "Copyright (c) 2016", doc.copyright
    assert_equal @yesterday,           doc.document_timestamp
  end

  def test_when_content_does_not_include_params_and_doc_attributes_exist_publish_keeps_the_doc_attributes
    config_values = {
        'action' => { 'workflow' => 'wf'},
        'input'  => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::READY ) },
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::PUBLISHED) },
      'field_map' => {
        'get_doc_id_from'        => '["account_number"]',
        'get_doc_title_from'     => '["title"]',
        'get_doc_timestamp_from' => '["timestamp"]',
        'get_doc_copyright_from' => '["copyright"]',
      }
    }

    content = {
      'NOT-account_number' => '101',
      'name'               => 'Brian',
      'email'              => 'brian@example.com',
      'phone'              => '555-1212',
      'NOT-timestamp'      => @yesterday,
      'NOT-copyright'      => "Copyright (c) 2016",
      'NOT-title'          => "New Title"
    }

    config = Armagh::StandardActions::HashPublish.create_configuration( [], 'hash_test', config_values )
    hash_publish = Armagh::StandardActions::HashPublish.new(@caller, @logger, config)

    doc = @doc.dup
    doc.content = content

    hash_publish.publish(doc)

    assert_equal @doc.document_id,        doc.document_id
    assert_equal @doc.title,              doc.title
    assert_equal @doc.copyright,          doc.copyright
    assert_equal @doc.document_timestamp, doc.document_timestamp
  end

  def test_when_content_does_not_include_params_and_doc_attributes_do_not_exist_publish_sets_document_attributes_from_source_or_metadata
    config_values = {
        'action' => { 'workflow' => 'wf'},
      'input'  => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::READY ) },
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::PUBLISHED) },
      'field_map' => {
        'get_doc_id_from'        => '["account_number"]',
        'get_doc_title_from'     => '["title"]',
        'get_doc_timestamp_from' => '["timestamp"]',
        'get_doc_copyright_from' => '["copyright"]',
      }
    }

    content = {
      'NOT-account_number' => '101',
      'name'               => 'Brian',
      'email'              => 'brian@example.com',
      'phone'              => '555-1212',
      'NOT-timestamp'      => @yesterday,
      'NOT-copyright'      => "Copyright (c) 2016",
      'NOT-title'          => "New Title"
    }

    config = Armagh::StandardActions::HashPublish.create_configuration( [], 'hash_test', config_values )
    hash_publish = Armagh::StandardActions::HashPublish.new(@caller, @logger, config)

    doc = @doc.dup
    doc.content = content
    doc.title              = nil
    doc.copyright          = nil
    doc.document_timestamp = nil

    assert_not_equal '101',                        doc.document_id,        'pre-condition'
    assert_not_equal @source.filename,             doc.title,              'pre-condition'
    assert_not_equal @metadata.first['copyright'], doc.copyright,          'pre-condition'
    assert_not_equal @source.mtime,                doc.document_timestamp, 'pre-condition'

    hash_publish.publish(doc)

    assert_equal @doc.document_id,             doc.document_id
    assert_equal @source.filename,             doc.title
    assert_equal @metadata.first['copyright'], doc.copyright
    assert_equal @source.mtime,                doc.document_timestamp
  end

  def test_description_has_field_map
    assert_match /field_map/, Armagh::StandardActions::HashPublish.description, 'HashPublish.description should mention "field_map"'
  end
end
