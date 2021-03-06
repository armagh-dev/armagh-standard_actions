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

require_relative '../../../../lib/armagh/standard_actions/publishers/text_publish'

class TestTextPublish < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    collection = mock

    @config_values = {
      'action' => { 'name' => 'text_test', 'workflow' => 'wf' },
      'input'  => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::READY ) },
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::PUBLISHED) }
    }
    @config = Armagh::StandardActions::TextPublish.create_configuration( [], 'text_test', @config_values )
    @text_publish_action = Armagh::StandardActions::TextPublish.new(@caller, @logger, @config)
    @id = '123'
    @content = {}
    @raw = nil 
    @metadata = {}
    @time = Time.now
    @source = stub('source', 'filename' => "some_file.txt",
                             'mtime'     => @time
                  )
    @title = 'title'
    @copyright = 'copyright'
    @document_timestamp = Time.at(10_000).utc
    @doc = Armagh::Documents::ActionDocument.new(
      document_id: @id,
      content:     @content,
      raw:         @raw,
      metadata:    @metadata,
      docspec:     @config.output.docspec,
      source:      @source,
      title:       @title,
      copyright:   @copyright,
      document_timestamp: @document_timestamp
    )
  end

  def test_publish_saves_filename_as_document_title
    expected_contents = 'hello world'
    @doc.title = nil
    @doc.raw = expected_contents
    @text_publish_action.publish(@doc)
    assert_equal @source.filename, @doc.title
  end

  def test_publish_saves_mtime_as_document_timestamp
    expected_contents = @time.to_s
    @doc.document_timestamp = nil
    @doc.raw = expected_contents
    @text_publish_action.publish(@doc)
    assert_equal @source.mtime, @doc.document_timestamp
  end

  def test_publish_copies_draft_content_to_published_content
    expected_contents = 'hello world'
    @doc.raw = expected_contents
    @text_publish_action.publish(@doc)
    assert_equal expected_contents, @doc.content['text_content']
  end

end
