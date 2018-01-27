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

require_relative '../../../../lib/armagh/standard_actions/splitters/csv_split'
require_relative '../../../helpers/actions_test_helper'

class TestCSVSplit < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @logger         = mock('logger')
    @caller         = mock('caller')
    @config = Armagh::StandardActions::CSVSplit.create_configuration([], 'test', {
        'action' => { 'workflow' => 'wf'},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('OutputDocument', Armagh::Documents::DocState::READY)},
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_in', Armagh::Documents::DocState::READY )},
    })
  end

  def test_it_creates_documents_with_draft_content_from_each_row_from_source_file
    csv_path   = "./test/fixtures/test.csv"
    doc        = mock('document', {raw: File.read(csv_path)})


    @caller.expects(:edit_document).at_least_once
    splitter_action = instantiate_action(Armagh::StandardActions::CSVSplit, @config)
    splitter_action.split(doc)
  end

  def test_calls_notify_ops_when_csv_content_has_row_with_missing_value
    csv_row_with_missing_value_path = "./test/fixtures/row_with_missing_value.csv"
    doc = mock('missing_value_document', raw: File.read(csv_row_with_missing_value_path))

    @caller.expects(:edit_document).at_least_once
    @caller.expects(:notify_ops).at_least_once
    splitter_action = instantiate_action(Armagh::StandardActions::CSVSplit, @config)
    splitter_action.split(doc)
  end

  def test_calls_notify_ops_when_csv_content_has_row_with_extra_values
    csv_row_with_extra_values_path = "./test/fixtures/row_with_extra_values.csv"
    doc = mock('extra_value_document', raw: File.read(csv_row_with_extra_values_path))

    @caller.expects(:edit_document).at_least_once
    @caller.expects(:notify_ops).at_least_once
    splitter_action = instantiate_action(Armagh::StandardActions::CSVSplit, @config)
    splitter_action.split(doc)
  end

end
