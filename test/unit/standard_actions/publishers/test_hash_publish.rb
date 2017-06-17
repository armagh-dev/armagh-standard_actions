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
    @logger = mock
    @caller = mock
    collection = mock

    @config_values = {
      'input'  => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::READY ) },
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::PUBLISHED) },
      'hash_publish' => {
        'id_field'  => ["account_number"],
        'timestamp' => ["timestamp"],
        'copyright' => ["copyright"],
        'title'     => ['title']
      }
    }
    @config = Armagh::StandardActions::HashPublish.create_configuration( [], 'hash_test', @config_values )
    @hash_publish = Armagh::StandardActions::HashPublish.new(@caller, @logger, @config, collection)
    @time = Time.now
    @content = {
      'account_number' => '101',
      'name'           => 'Brian',
      'email'          => 'brian@example.com',
      'phone'          => '555-1212',
      'timestamp'      => @time,
      'copyright'      => "Copyright (c) 2016",
      'title'          => "Some Title"
    }
    @raw = ''
    @metadata = {
      'copyright' => 'Some copyright notice'
    },
    @source = stub('source', 'filename' => "some_file.csv",
                             'mtime'     => @time,
                  )
    @draft_docspec = Armagh::Documents::DocSpec.new('doctype', Armagh::Documents::DocState::PUBLISHED)
    @doc = Armagh::Documents::ActionDocument.new(
      document_id:        @id,
      content:            @content,
      raw:                @raw,
      metadata:           @metadata,
      docspec:            @draft_docspec,
      source:             @source,
      title:              @content['title'],
      copyright:          @content['copyright'],
      document_timestamp: @content['timestamp']
    )
  end

  test "publish sets document attributes" do
    id_field = @config.hash_publish.id_field.map(&:strip).join(",")
    title = @config.hash_publish.title.map(&:strip).join(",")
    copyright = @config.hash_publish.copyright.map(&:strip).join(",")

    @hash_publish.publish(@doc)

    assert_equal @doc.content[id_field],  @doc.document_id
    assert_equal @doc.content[title],     @doc.title
    assert_equal @doc.content[copyright], @doc.copyright
    assert_equal @time,                   @doc.document_timestamp
  end

end
