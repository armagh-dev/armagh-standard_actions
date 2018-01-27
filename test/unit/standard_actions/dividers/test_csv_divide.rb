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

require_relative '../../../../lib/armagh/standard_actions/dividers/csv_divide'
require_relative '../../../helpers/actions_test_helper'

class TestCSVDivide < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    fixtures_path = File.join(__dir__, '..', '..', '..', 'fixtures')
    @csv_path     = File.join fixtures_path, 'test.csv'

    @logger         = mock
    @caller         = mock
    @output_docspec = mock
    @collection     = mock
    @collected_doc  = mock('collected_document')

    @config_values = {
      'action' => { 'workflow' => 'wf'},
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_doctype', Armagh::Documents::DocState::READY ) },
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new( 'divided_doctype', Armagh::Documents::DocState::READY ) },
      'csv_divider' => {
        'size_per_part' => 100
      }
    }
    @config = Armagh::StandardActions::CSVDivide.create_configuration([], 'testdiv', @config_values )
    @divider_action = instantiate_action(Armagh::StandardActions::CSVDivide, @config)
  end

  def test_it_creates_documents_with_draft_content_from_divided_parts_of_larger_source_file
    @caller.expects(:create_document).at_least_once
    @collected_doc.expects(:metadata).at_least_once.returns({})
    @divider_action.doc_details = {}
    @collected_doc.expects(:collected_file).at_least_once.returns(@csv_path)

    @divider_action.divide(@collected_doc)
  end

  def test_calls_notify_when_csv_library_errors_when_dividing_source_csv_file
    @caller.expects(:create_document).never
    @caller.expects(:notify_dev).at_least_once
    @divider_action.stubs(:divided_parts).raises(CSVDivider::RowMissingValueError)

    @divider_action.divide(@collected_doc)
  end
end
