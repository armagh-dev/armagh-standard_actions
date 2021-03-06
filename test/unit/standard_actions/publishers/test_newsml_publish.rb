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
require 'tzinfo'

require_relative '../../../../lib/armagh/standard_actions/publishers/newsml_publish'

class TestNewsmlPublish < Test::Unit::TestCase

  def setup
    @logger = mock('logger')
    @caller = mock('caller')
    @collection = mock('collection')
    @config_values = {
        'action' => { 'workflow' => 'wf'},
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::READY ) },
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::PUBLISHED) },
    }
    @config = Armagh::StandardActions::NewsmlPublish.create_configuration( [], 'test', @config_values )
    @newsml_publish_action = Armagh::StandardActions::NewsmlPublish.new( @caller, @logger, @config )
    @doc = Armagh::Documents::ActionDocument.new(
      document_id: 'doc_id',
      title: 'title',
      copyright: 'copyright',
      content: {'content' => true},
      raw: 'hello world',
      metadata: {'meta' => true},
      docspec: @config.output.docspec,
      source: 'news source',
      document_timestamp: Time.now
    )
    @contents_hash = {
      'NewsML' => {
        'NewsEnvelope' => {
          'TransmissionId' => '260616127'
        },
        'NewsItem' => {
          'Identification' => {
            'NewsIdentifier' => {
              'NewsItemId' => '193e7679'
            }
          },
          'NewsManagement' => {
            'FirstCreated' => '20130712T154259'
          },
          'NewsComponent' => {
            'NewsLines' => {
              'HeadLine' => 'breaking news',
              'CopyrightLine' => 'copyright line'
            },
            'AdministrativeMetadata' => {
              'Property' => {
                'attr_FormalName'=>'SourceCode',
                'attr_Value' => 'ABW'
              }
            },
            'DescriptiveMetadata' => {
              'Language' => {
                'attr_FormalName' => 'english'
              }
            },
            'ContentItem' => {
              'DataContent' => {
                'body' => {
                  'body.head' => {
                    'distributor' => 'Al Bawaba Business'
                  }
                }
              }
            }
          }
        }
      }
    }

    @newsml_publish_action.stubs(:to_hash).returns(@contents_hash)
  end

  def test_publish_sets_metadata

    expected_ts = "20130712T154259"
    ny_tz = TZInfo::Timezone.get('America/New_York').period_for_utc(Time.parse(expected_ts)).zone_identifier.to_s
    ny_tz_offset = (ny_tz == :EST) ? '-0500' : '-0400'

    @newsml_publish_action.stubs(:html_to_text).returns(['breaking news', 'copyright line', 'body'])
    @newsml_publish_action.publish(@doc)
    assert_equal '260616127', @doc.document_id
    assert_equal Time.parse( "#{expected_ts}#{ ny_tz_offset }" ), @doc.document_timestamp
    assert_equal 'breaking news', @doc.title
    assert_equal 'copyright line', @doc.copyright
    assert_equal 'ABW', @doc.metadata['source_code']
    assert_equal 'english', @doc.metadata['language']
    assert_equal 'Al Bawaba Business', @doc.metadata.dig(*%w(tacball_consume source))
  end

  def test_publish_sets_contents
    expected_contents = ''
    @newsml_publish_action.stubs(:html_to_text).returns(['title', 'copyright', ''])
    @newsml_publish_action.publish(@doc)
    assert_equal expected_contents, @doc.content['text_content']
  end

  def test_publish_bad_timestamp
    @newsml_publish_action.stubs(:html_to_text).returns(%w(title copyright body))
    @contents_hash['NewsML']['NewsItem']['NewsManagement']['ThisRevisionCreated'] = 'invalid'
    @newsml_publish_action.expects(:notify_ops).with('Timestamp empty or not valid')
    @newsml_publish_action.publish(@doc)
  end

  def test_empty_title
    @doc.title = nil
    @newsml_publish_action.stubs(:html_to_text).returns(['', 'copyright', 'body'])
    @contents_hash['NewsML']['NewsItem']['NewsComponent']['NewsLines']['HeadLine'] = ''
    @newsml_publish_action.publish(@doc)
    assert_empty @doc.title
  end

  def test_empty_copyright
    @doc.copyright = nil
    @newsml_publish_action.stubs(:html_to_text).returns(['title', '', 'body'])
    @contents_hash['NewsML']['NewsItem']['NewsComponent']['NewsLines']['CopyrightLine'] = ''
    @newsml_publish_action.publish(@doc)
    assert_empty @doc.copyright
  end
end
