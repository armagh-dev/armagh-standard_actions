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

require_relative '../../../../lib/armagh/standard_actions/splitters/json_split'
require_relative '../../../helpers/actions_test_helper'

class FakeDocument

  attr_accessor :content, :raw, :metadata

  def initialize
    @content = {}
    @raw = ''
    @metadata = {}
  end

end

class TestJSONSplit < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @caller        = mock('caller')
    @config_values = {
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dan_indoc', Armagh::Documents::DocState::READY )},
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_output', Armagh::Documents::DocState::READY )},
      'json_splitter' => {'split_target' => 'employees'}
    }
    @config = Armagh::StandardActions::JSONSplit.create_configuration([], 'test', @config_values)

    fixtures_path  = File.join(__dir__, '..', '..', '..', 'fixtures')
    @json_path     = File.join fixtures_path, 'test.json'
    @json_content  = File.read(@json_path)
  end

  def test_split_with_valid_json
    doc = mock('document')
    doc.expects(:raw).returns(@json_content)

    @caller.expects(:edit_document).at_least_once
    splitter = instantiate_action(Armagh::StandardActions::JSONSplit, @config)
    splitter.split(doc)
  end

  def test_split_with_invalid_json
    doc = mock('document')
    doc.expects(:raw).returns(['not', 'json'])
    Armagh::StandardActions::JSONSplit.any_instance.expects(:edit_document).never
    Armagh::StandardActions::JSONSplit.any_instance.expects(:notify_ops).at_least_once
    Armagh::StandardActions::JSONSplit.any_instance.expects(:split_parts).once.raises(Armagh::Support::JSON::Splitter::JSONTypeError)
    splitter = instantiate_action(Armagh::StandardActions::JSONSplit, @config)
    splitter.split(doc)
  end

end
