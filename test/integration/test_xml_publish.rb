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

require_relative '../helpers/coverage_helper'
require_relative '../helpers/actions_test_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../lib/armagh/standard_actions/publishers/xml_publish'

class TestIntegrationXmlPublish < Test::Unit::TestCase

  include ActionsTestHelper

  def setup
    @config_values = {
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new('dans_in', Armagh::Documents::DocState::READY) },
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new('dans_in', Armagh::Documents::DocState::PUBLISHED) },
      'xml' => {
        'get_doc_id_from' => ['NewsML', 'NewsItem', 'Identification', 'NewsIdentifier', 'NewsItemId'],
        'get_doc_title_from' => ['NewsML', 'NewsItem', 'NewsComponent', 'NewsLines', 'HeadLine'],
        'get_doc_timestamp_from' => ['NewsML', 'NewsItem', 'NewsManagement', 'FirstCreated'],
        'get_doc_copyright_from' => ['NewsML', 'NewsItem', 'NewsComponent', 'NewsLines', 'CopyrightLine'],
        'html_nodes' => ['body.content']
      }
    }
    @config = Armagh::StandardActions::XmlPublish.create_configuration([], 'xml_test', @config_values)
    @xml_publish_action = instantiate_action(Armagh::StandardActions::XmlPublish, @config)
    @docspec = Armagh::Documents::DocSpec.new('doctype', Armagh::Documents::DocState::PUBLISHED)
    @doc = Armagh::Documents::ActionDocument.new(
      document_id: 'doc_id',
      title: 'title',
      copyright: 'copyright',
      content: {'content' => true},
      raw: 'hello world',
      metadata: {'meta' => true},
      docspec: @docspec,
      source: 'news source',
      document_timestamp: Time.now
    )
  end

  def test_publish_sets_document_contents_and_attributes
    xml_file = 'test/fixtures/comtex_sample1.xml'
    @doc.raw = File.read(xml_file, mode:'rb')
    expected_xml_hash = eval(File.read('test/fixtures/comtex_sample1_xml_hash.txt', mode:'rb'))
    @xml_publish_action.publish(@doc)
    assert_equal expected_xml_hash, @doc.content
    assert_equal '277p3476', @doc.document_id
    assert_equal 'Marriott International Announces Release Date For Third Quarter 2016 Earnings', @doc.title
    assert_equal Time.parse('20161003T110900'), @doc.document_timestamp
    assert_equal "Copyright (C) 2016 PR Newswire. All rights reserved", @doc.copyright
  end

end
