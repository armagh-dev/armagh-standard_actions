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

require_relative '../../../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../../lib/armagh/standard_actions/dividers/json_divide'
require_relative '../../../helpers/actions_test_helper'

class TestJSONDivide < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    fixtures_path = File.join(__dir__, '..', '..', '..', 'fixtures')
    @json_path     = File.join fixtures_path, 'test.json'

    @logger         = mock
    @caller         = mock
    @output_docspec = mock
    @collection     = mock
    @collected_doc  = mock('collected_document')

    @default_config_values = {
        'action' => { 'workflow' => 'wf'},
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_doctype', Armagh::Documents::DocState::READY ) },
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new( 'divided_doctype', Armagh::Documents::DocState::READY ) },
      'json_divider' => {
        'size_per_part' => 250,
        'divide_target' => 'employees'
      }
    }
    @default_config = Armagh::StandardActions::JSONDivide.create_configuration([], 'test_json_div', @default_config_values )
  end

  def test_it_creates_documents_with_draft_content_from_divided_parts_of_larger_source_JSON_file
    @caller.expects(:create_document).at_least_once
    @caller.expects(:notify_ops).never
    @collected_doc.expects(:metadata).at_least_once.returns({})
    @collected_doc.expects(:collected_file).at_least_once.returns(@json_path)

    @divider_action = Armagh::StandardActions::JSONDivide.new( @caller, 'logger_name', @default_config )
    @divider_action.doc_details = {}
    @divider_action.divide(@collected_doc)
  end

  def test_calls_notify_when_json_library_errors_when_dividing_source_json_file
    @caller.expects(:create_document).never
    @caller.expects(:notify_dev).at_least_once
    @divider_action = Armagh::StandardActions::JSONDivide.new( @caller, 'logger_name', @default_config )
    @divider_action.stubs(:divided_parts).raises(JSONDivider::SizeError)
    @divider_action.divide(@collected_doc)
  end
end
