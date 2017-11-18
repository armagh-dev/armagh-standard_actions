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

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../../lib/armagh/standard_actions/dividers/xml_divide'
require_relative '../../../helpers/actions_test_helper'

class TestXMLDivide < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    fixtures_path = File.join(__dir__, '..', '..', '..', 'fixtures')
    @xml_path     = File.join fixtures_path, 'big_xml.xml'

    @logger         = mock
    @caller         = mock
    @output_docspec = mock
    @collection     = mock
    @collected_doc  = mock('collected_document')

    @config_values = {
        'action' => { 'workflow' => 'wf'},
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dan_indoc', Armagh::Documents::DocState::READY )},
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_output', Armagh::Documents::DocState::READY )},
      'xml_divide' => {'size_per_part' => 1000, 'xml_element' => 'sdnEntry'}
    }
    @config = Armagh::StandardActions::XMLDivide.create_configuration( [], 'test', @config_values )
    @divider_action = instantiate_action(Armagh::StandardActions::XMLDivide, @config)
  end

  def test_it_creates_documents_with_draft_content_from_divided_parts_of_larger_source_file
    @caller.expects(:create_document).at_least_once
    @caller.expects(:notify_ops).never
    @collected_doc.expects(:metadata).at_least_once.returns({})
    @collected_doc.expects(:collected_file).at_least_once.returns(@xml_path)

    @divider_action.doc_details = {}
    @divider_action.divide(@collected_doc)
  end

  def test_calls_notify_ops_when_xml_library_errors_when_dividing_source_xml_file
    @caller.expects(:create_document).never
    @caller.expects(:notify_ops).at_least_once
    @divider_action.stubs(:divided_parts).raises(Armagh::Support::XML::Divider::MaxSizeTooSmallError)
    @divider_action.divide(@collected_doc)
  end
end
