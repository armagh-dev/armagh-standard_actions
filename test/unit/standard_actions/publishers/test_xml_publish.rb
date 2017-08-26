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
      'field_map' => {
        "get_doc_id_from" => ['sdnList', 'sdnEntry', 'uid'],
        "get_doc_title_from" => ['sdnList', 'sdnEntry', 'lastName'],
        "get_doc_timestamp_from" => ['sdnList', 'publshInformation', 'Publish_Date'],
        'get_doc_copyright_from' => ['here', 'is', 'copyright'],
      },
      'xml' => {
        'html_nodes' => ['node1', 'node2']
      },
      "time_parser" => {
        "time_format" => "%m/%d/%Y",
      }
    }
    @config = Armagh::StandardActions::XmlPublish.create_configuration([], 'xml_test', @config_values)
    @xml_publish_action = instantiate_action(Armagh::StandardActions::XmlPublish, @config)
    @docspec = Armagh::Documents::DocSpec.new('doctype', Armagh::Documents::DocState::PUBLISHED)
    @doc = Armagh::Documents::ActionDocument.new(
      document_id: 'doc_id',
      title: 'title',
      copyright: 'Copyright (c) 2016',
      content: {'content' => true},
      raw: 'hello world',
      metadata: {'meta' => true},
      docspec: @docspec,
      source: 'news source',
      document_timestamp: Time.now.to_s
    )
  end

  def test_publish_sets_contents
    timestamp = '20161003T110900'
    Armagh::Support::XML.stubs(:get_doc_attr).with(is_a(Hash), is_a(Array)).returns('abc123', 'Breaking News', timestamp, 'Copyright Line')
    xml_file = 'test/fixtures/big_xml.xml'
    @doc.raw = File.read(xml_file, mode:'rb')
    @xml_publish_action.publish(@doc)
    assert_equal JSON.parse(File.read("test/fixtures/ofac_xml_hash.txt")), @doc.content
  end

  def test_publish_sets_document_attributes
    timestamp = "2014-05-30 00:00:00"
    Armagh::Support::XML.stubs(:get_doc_attr).with(is_a(Hash), is_a(Array)).returns('abc123', 'Breaking News', timestamp, 'Copyright Line')
    xml_file = 'test/fixtures/big_xml.xml'
    @doc.raw = File.read(xml_file, mode:'rb')
    @xml_publish_action.publish(@doc)
    assert_equal '10', @doc.document_id
    assert_equal 'ABASTECEDORA NAVAL Y INDUSTRIAL, S.A.', @doc.title
    assert_equal Time.parse("#{timestamp} UTC"), @doc.document_timestamp
    assert_equal 'Copyright (c) 2016', @doc.copyright
  end

  test "description has field_map" do
    assert_match /field_map/, Armagh::StandardActions::XmlPublish.description, 'XmlPublish.description should mention "field_map"'
  end
end
