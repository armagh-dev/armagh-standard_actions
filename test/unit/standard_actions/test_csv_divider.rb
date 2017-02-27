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

require_relative '../../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../lib/armagh/standard_actions/csv_divider'
require_relative '../../helpers/actions_test_helper'

class TestCSVDivider < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    fixtures_path = File.join(__dir__, '..', '..', 'fixtures')
    @csv_path     = File.join fixtures_path, 'test.csv'
  end

  test "it creates documents with draft_content from divided parts of larger source file" do
    @config_values = {
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_doctype', Armagh::Documents::DocState::READY ) },
      'csv_divider' => {
        'size_per_part' => 100
      }
    }
    @config = Armagh::StandardActions::CSVDivider.create_configuration([], 'testdiv', @config_values )

    @divider_action = instantiate_action(Armagh::StandardActions::CSVDivider, @config)

    @caller.expects(:create_document).at_least_once

    @divider_action.doc_details = {}
    @divider_action.divide(@csv_path, @config)
  end

end
