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
require 'webmock/test_unit'

require 'armagh/documents/published_document'
require_relative '../../../../lib/armagh/standard_actions/consumers/rest_consume'


class TestRESTConsume < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @docspec = Armagh::Documents::DocSpec.new('doc', Armagh::Documents::DocState::PUBLISHED)
    @config_values = {
      'action' => {'workflow' => 'wf'},
      'input' => {'docspec' => @docspec},
      'http' => {
        'url' => 'http://test.url',
      }
    }
    @config = Armagh::StandardActions::RESTConsume.create_configuration([], 'test', @config_values)
    @rest_consume_action = instantiate_action(Armagh::StandardActions::RESTConsume, @config)

    @doc = Armagh::Documents::PublishedDocument.new(
      document_id: 'id',
      title: 'title',
      copyright: 'copyright',
      content: {'content' => true},
      raw: '',
      metadata: {'meta' => true},
      docspec: @docspec,
      source: Armagh::Documents::Source.new(filename: 'file.txt'),
      document_timestamp: Time.at(300_000_000).utc
    )
  end

  def test_consume
    stub_request(:post, @config.http.url).with(body: @doc.to_json)
    @rest_consume_action.consume(@doc)
  end

  def test_consume_error
    stub_request(:post, @config.http.url).to_return(:status => 404)
    @caller.expects(:notify_ops)
    @rest_consume_action.consume(@doc)
  end
end
