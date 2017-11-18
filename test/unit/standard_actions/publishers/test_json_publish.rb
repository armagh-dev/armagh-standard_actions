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
require 'facets/time'

require_relative '../../../../lib/armagh/standard_actions/publishers/json_publish'
require_relative '../../../helpers/actions_test_helper'

class TestJsonPublish < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @now       = Time.now
    @yesterday = @now.ago(1, :day)
    @last_week = @now.ago(1, :week)

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
    config = Armagh::StandardActions::JsonPublish.create_configuration( [], 'json_test', config_values )

    @json_publish_action = instantiate_action(Armagh::StandardActions::JsonPublish, config)

    draft_docspec = Armagh::Documents::DocSpec.new('doctype', Armagh::Documents::DocState::PUBLISHED)
    @metadata = {
      'copyright' => 'Metadata copyright notice'
    },
    @source = stub('source', 'filename' => "source_file.csv",
                             'mtime'     => @last_week,
                  )

    @doc = Armagh::Documents::ActionDocument.new(
      document_id:        'Orig id',
      content:            {'key' => 'Orig content'},
      raw:                '',
      metadata:           @metadata,
      docspec:            draft_docspec,
      source:             @source,
      title:              'Orig title',
      copyright:          'Orig copyright',
      document_timestamp: @now,
    )
  end

  def test_when_json_is_nested_publish_sets_document_attributes
    config_values_nested = {
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
    config = Armagh::StandardActions::JsonPublish.create_configuration( [], 'json_test', config_values_nested )
    json_publish_action = instantiate_action(Armagh::StandardActions::JsonPublish, config)

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
    json = JSON.generate(content)

    doc = @doc.dup
    doc.raw = json

    assert_not_equal    '101',                doc.document_id,           'pre-condition'
    assert_not_equal    "New Title",          doc.title,                 'pre-condition'
    assert_not_equal    "Copyright (c) 2016", doc.copyright,             'pre-condition'
    assert_not_in_delta @yesterday,           doc.document_timestamp, 1, 'pre-condition'

    json_publish_action.publish(doc)

    assert_equal    '101',                doc.document_id
    assert_equal    "New Title",          doc.title
    assert_equal    "Copyright (c) 2016", doc.copyright
    assert_in_delta @yesterday,           doc.document_timestamp, 1
  end

  def test_when_json_is_not_nested_publish_sets_document_attributes
    content = {
      'account_number' => '101',
      'name'           => 'Brian',
      'email'          => 'brian@example.com',
      'phone'          => '555-1212',
      'timestamp'      => @yesterday,
      'copyright'      => "Copyright (c) 2016",
      'title'          => "New Title"
    }
    json = JSON.generate(content)

    doc = @doc.dup
    doc.raw = json

    assert_not_equal    '101',                doc.document_id,           'pre-condition'
    assert_not_equal    "New Title",          doc.title,                 'pre-condition'
    assert_not_equal    "Copyright (c) 2016", doc.copyright,             'pre-condition'
    assert_not_in_delta @yesterday,           doc.document_timestamp, 1, 'pre-condition'

    @json_publish_action.publish(doc)

    assert_equal    '101',                doc.document_id
    assert_equal    "New Title",          doc.title
    assert_equal    "Copyright (c) 2016", doc.copyright
    assert_in_delta @yesterday,           doc.document_timestamp, 1
  end

  def test_when_json_does_not_include_params_and_doc_attributes_exist_publish_keeps_the_doc_attributes
    content = {
      'NOT-account_number' => '101',
      'name'               => 'Brian',
      'email'              => 'brian@example.com',
      'phone'              => '555-1212',
      'NOT-timestamp'      => @yesterday,
      'NOT-copyright'      => "Copyright (c) 2016",
      'NOT-title'          => "New Title"
    }
    json = JSON.generate(content)

    doc = @doc.dup
    doc.raw = json

    @json_publish_action.publish(doc)

    assert_equal @doc.document_id,        doc.document_id
    assert_equal @doc.title,              doc.title
    assert_equal @doc.copyright,          doc.copyright
    assert_equal @doc.document_timestamp, doc.document_timestamp
  end

  def test_when_json_does_not_include_params_and_doc_attributes_do_not_exist_publish_sets_document_attributes_from_source_or_metadata
    content = {
      'NOT-account_number' => '101',
      'name'               => 'Brian',
      'email'              => 'brian@example.com',
      'phone'              => '555-1212',
      'NOT-timestamp'      => @yesterday,
      'NOT-copyright'      => "Copyright (c) 2016",
      'NOT-title'          => "New Title"
    }
    json = JSON.generate(content)

    doc = @doc.dup
    doc.raw = json
    doc.title              = nil
    doc.copyright          = nil
    doc.document_timestamp = nil

    assert_not_equal '101',                        doc.document_id,        'pre-condition'
    assert_not_equal @source.filename,             doc.title,              'pre-condition'
    assert_not_equal @metadata.first['copyright'], doc.copyright,          'pre-condition'
    assert_not_equal @source.mtime,                doc.document_timestamp, 'pre-condition'

    @json_publish_action.publish(doc)

    assert_equal @doc.document_id,             doc.document_id
    assert_equal @source.filename,             doc.title
    assert_equal @metadata.first['copyright'], doc.copyright
    assert_equal @source.mtime,                doc.document_timestamp
  end

  def test_Hash_round_trip
    content = {
      'account' => {
        'account_number' => '101',
        'name'           => 'Brian',
        'email'          => 'brian@example.com',
        'phone'          => '555-1212',
      },
      'NOT-timestamp'  => "not a timestamp",
      'copyright'      => "Copyright (c) 2016",
      'title'          => "New Title"
    }
    json = JSON.generate(content)

    doc = @doc.dup
    doc.raw = json

    assert_not_equal content, doc.content, 'pre-condition'

    @json_publish_action.publish(doc)

    assert_equal content, doc.content
  end

  def test_when_given_a_JSON_null_publish_sets_content_to_Hash_with_key_json_and_value_nil
    json = 'null'

    doc = @doc.dup
    doc.raw = json

    assert_not_include doc.content, 'json', 'pre-condition'

    @json_publish_action.publish(doc)

    assert_include doc.content, 'json'
    assert_nil     doc.content[ 'json']
  end

  def test_when_given_a_JSON_string_publish_sets_doc_text
    raw  = 'this is a JSON string'
    json = JSON.generate(raw)

    doc = @doc.dup
    doc.raw = json

    assert_not_include doc.content, 'json',   'pre-condition'
    assert_not_equal   raw,         doc.text, 'pre-condition'

    @json_publish_action.publish(doc)

    assert_not_include doc.content, 'json'
    assert_equal       raw,         doc.text
  end

  def test_when_given_a_JSON_array_publish_sets_content_to_Hash_with_key_json_and_value_array
    raw = [
            'a String',
            {
              'hash String' => 'a Hash String',
              'hash Array'  => [
                1,
                'hash Array 1',
              ],
              'hash Hash'   => {
                'key' => 'nested Hash',
              },
            },
            [
              'a nested Array',
              1,
            ],
          ]
    json = JSON.generate(raw)

    doc = @doc.dup
    doc.raw = json

    assert_not_include doc.content, 'json', 'pre-condition'

    @json_publish_action.publish(doc)

    assert_include      doc.content, 'json'
    assert_equal   raw, doc.content[ 'json']
  end

  def test_when_given_invalid_json_publish_raises_JSON_exception
    json = '{"this is invalid json"'

    doc = @doc.dup
    doc.raw = json

    assert_raise Armagh::StandardActions::JsonPublish::InvalidJsonError.new('Unable to parse JSON') do
      @json_publish_action.publish(doc)
    end
  end

  def test_description_has_field_map
    assert_match /field_map/, Armagh::StandardActions::JsonPublish.description, 'JsonPublish.description should mention "field_map"'
  end
end
