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

require_relative '../../../helpers/coverage_helper'
require_relative '../../../helpers/actions_test_helper'

require 'test/unit'
require 'mocha/test_unit'
require 'bson'
require 'time'

require_relative '../../../../lib/armagh/standard_actions/publishers/xml_publish'

class TestXmlPublish < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    caller_instance = mock('caller_instance')
    logger = mock('logger')
    @config_values = {
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new('dans_in', Armagh::Documents::DocState::READY) },
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new('dans_in', Armagh::Documents::DocState::PUBLISHED) },
      'xml' => {
        'get_doc_id_from' => ['here', 'is', 'docid'],
        'get_doc_title_from' => ['here', 'is', 'title'],
        'get_doc_timestamp_from' => ['here', 'is', 'timestamp'],
        'get_doc_copyright_from' => ['here', 'is', 'copyright'],
        'html_nodes' => ['node1', 'node2']
      }
    }
    @config = Armagh::StandardActions::XmlPublish.create_configuration([], 'xml_test', @config_values)
    @xml_publish_action = instantiate_action(Armagh::StandardActions::XmlPublish, @config)
    @docspec = Armagh::Documents::DocSpec.new('doctype', Armagh::Documents::DocState::PUBLISHED)
    @doc = Armagh::Documents::ActionDocument.new(
      document_id: 'doc_id',
      title: 'title',
      copyright: 'copyright',
      content: {'bson_binary' => BSON::Binary.new('hello world')},
      metadata: {'meta' => true},
      docspec: @docspec,
      source: 'news source',
      document_timestamp: Time.now
    )
  end

  def test_publish_sets_contents
    timestamp = '20161003T110900'
    Armagh::Support::XML.stubs(:to_hash).with(is_a(String), is_a(Array)).once.returns({'some_key' => 'some_value'})
    Armagh::Support::XML.stubs(:get_doc_attr).with(is_a(Hash), is_a(Array)).returns('abc123', 'Breaking News', timestamp, 'Copyright Line')
    xml_file = 'test/fixtures/big_xml.xml'
    @doc.content['bson_binary'] = BSON::Binary.new(File.read(xml_file, mode:'rb'))
    @xml_publish_action.publish(@doc)
    assert_equal ({'some_key' => 'some_value'}), @doc.content
  end

  def test_publish_sets_document_attributes
    timestamp = '20161003T110900'
    Armagh::Support::XML.stubs(:to_hash).with(is_a(String), is_a(Array)).once.returns({'some_key' => 'some_value'})
    Armagh::Support::XML.stubs(:get_doc_attr).with(is_a(Hash), is_a(Array)).returns('abc123', 'Breaking News', timestamp, 'Copyright Line')
    xml_file = 'test/fixtures/big_xml.xml'
    @doc.content['bson_binary'] = BSON::Binary.new(File.read(xml_file, mode:'rb'))
    @xml_publish_action.publish(@doc)
    assert_equal 'abc123', @doc.document_id
    assert_equal 'Breaking News', @doc.title
    assert_equal Time.parse(timestamp), @doc.document_timestamp
    assert_equal 'Copyright Line', @doc.copyright
  end
end
