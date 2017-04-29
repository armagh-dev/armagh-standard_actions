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

class TestXMLDivide < Test::Unit::TestCase

  def setup
    @logger         = mock
    @caller         = mock
    @output_docspec = mock
    @collection     = mock

    fixtures_path = File.join(__dir__, '..', '..', '..', 'fixtures')
    @xml_path     = File.join fixtures_path, 'big_xml.xml'
    @config_values = {
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dan_indoc', Armagh::Documents::DocState::READY )},
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_output', Armagh::Documents::DocState::READY )},
      'xml' => {'size_per_part' => 1000, 'xml_element' => 'sdnEntry'}
    }
    @config = Armagh::StandardActions::XMLDivide.create_configuration( [], 'test', @config_values )

  end

  test "it creates documents with draft_content from divided parts of larger source file" do
    @caller.expects(:create_document).at_least_once
    @caller.expects(:notify_ops).never
    @divider_action = Armagh::StandardActions::XMLDivide.new( @caller, 'logger_name', @config, @collection )
    @divider_action.doc_details = {}
    @divider_action.divide(@xml_path)
  end

  test "calls notify_ops when xml library errors when dividing source xml file" do
    Armagh::Support::XML.expects(:divided_parts).yields('', [Armagh::Support::XML::Divider::MaxSizeTooSmallError])
    @caller.expects(:create_document).never
    @caller.expects(:notify_ops).at_least_once
    @divider_action = Armagh::StandardActions::XMLDivide.new( @caller, 'logger_name', @config, @collection )
    @divider_action.divide(@xml_path,)
  end
end
