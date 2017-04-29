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
require 'bson'

require_relative '../../lib/armagh/standard_actions/publishers/newsml_publish'

class TestIntegrationNewsmlPublish < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    @collection = mock
    @config_values = {
      'action' => { 'name' => 'test' },
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::READY ) },
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::PUBLISHED) }
    }
    @config = Armagh::StandardActions::NewsmlPublish.create_configuration([], 'test', @config_values)
    @newsml_publish_action = Armagh::StandardActions::NewsmlPublish.new( @caller, @logger, @config, @collection )
    @id = '123'
    @content = {'bson_binary' => ''}
    @metadata = {'meta' => true}
    @source = 'news source'
    @doc = Armagh::Documents::ActionDocument.new(
      document_id: @id,
      content: @content,
      metadata: @metadata,
      docspec: @config.output.docspec,
      source: @source,
      title: nil,
      copyright: nil,
      document_timestamp: nil
    )
  end

  def test_publish_sets_metadata_and_contents
    ts_string = "20130712T154259"
    ny_tz = TZInfo::Timezone.get('America/New_York').period_for_utc(Time.parse(ts_string)).zone_identifier.to_s
    ny_tz_offset = (ny_tz == :EST) ? '-0500' : '-0400'
    expected_timestamp = Time.parse( "#{ts_string}#{ ny_tz_offset }" )
    xml_file = 'test/fixtures/hello_world.xml'
    @doc.raw = File.read(xml_file, mode:'rb')
    @newsml_publish_action.publish(@doc)
    assert_equal '193e7679', @doc.document_id
    assert_equal expected_timestamp, @doc.document_timestamp
    assert_equal 'Breaking News', @doc.title
    assert_equal 'Copyright (C) Euclid Infotech Pvt. Ltd. Provided by Syndigate.info an Albawaba.com company', @doc.copyright
    assert_equal 'ABW', @doc.metadata['source_code']
    assert_equal 'en', @doc.metadata['language']
    assert_equal 'Al Bawaba Business', @doc.metadata['source']
    assert_equal 'hello world', @doc.content['text_content']
  end

  def test_publish_sets_contents_with_nested_tables
    xml_file = 'test/fixtures/nested_tables.xml'
    @doc.raw = File.read(xml_file, mode:'rb')
    expected_contents = "hello world\n\nURL1\nONE  TWO\n\nwith nested tables"
    @newsml_publish_action.publish(@doc)
    assert_equal expected_contents, @doc.content['text_content']
  end

  def test_publish_sets_metadata_with_multiple_property_values
    xml_file = 'test/fixtures/comtex_sample1.xml'
    @doc.raw = File.read(xml_file, mode:'rb')
    @newsml_publish_action.publish(@doc)
    assert_equal 'PRN', @doc.metadata['source_code']
  end

  def test_publish_sets_metadata_with_multiple_news_component
    xml_file = 'test/fixtures/comtex_sample2.xml'
    @doc.raw = File.read(xml_file, mode:'rb')
    @newsml_publish_action.publish(@doc)
    assert_equal 'EQUITY ALERT: Rosen Law Firm Announces Investigation of Securities Claims Against Fusion Pharm, Inc.', @doc.title
  end

  # ARM-427
  def test_publish_with_subheadline
    xml_file = 'test/fixtures/comtex_sample3.xml'
    @doc.raw = File.read(xml_file, mode:'rb')
    @newsml_publish_action.publish(@doc)
    assert_equal 'Skydance Media Forms Exclusive Overall Agreement for Television with Award-Winning Writer-Producer Laeta Kalogridis', @doc.title
  end
end
