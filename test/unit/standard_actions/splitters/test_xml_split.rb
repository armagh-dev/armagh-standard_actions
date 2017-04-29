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

require_relative '../../../../lib/armagh/standard_actions/splitters/xml_split'
require_relative '../../../helpers/actions_test_helper'

class FakeDocument

  attr_accessor :content

  def initialize
    @content = {}
  end

end

class TestXMLSplit < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @config = mock('config')
  end

  def test_split_with_valid_xml
    doc = mock('document')
    doc.expects(:raw).returns('hello')
    chunks = ['chunk1', 'chunk2', 'chunk3']
    new_docs = []
    3.times do
      new_docs << FakeDocument.new
    end
    Armagh::StandardActions::XMLSplit.any_instance.stubs(:edit).yields(new_docs[0]).yields(new_docs[1]).yields(new_docs[2])
    Armagh::StandardActions::XMLSplit.any_instance.expects(:notify_ops).never
    Armagh::Support::XML::Splitter.stubs(:split).once.returns(chunks)
    xml_splitter_action = instantiate_action(Armagh::StandardActions::XMLSplit, @config)
    xml_splitter_action.split(doc)
    assert new_docs[0].content['xml'], 'chunk1'
    assert new_docs[1].content['xml'], 'chunk2'
    assert new_docs[2].content['xml'], 'chunk3'
  end

  def test_split_with_invalid_xml
    doc = mock('document')
    data = mock('bson binary')
    doc.expects(:raw).returns(['not', 'xml'])
    Armagh::StandardActions::XMLSplit.any_instance.expects(:edit_document).never
    Armagh::StandardActions::XMLSplit.any_instance.expects(:notify_ops).at_least_once
    Armagh::Support::XML::Splitter.stubs(:split).once.raises(Armagh::Support::XML::Splitter::XMLSplitError, "undefined method `split' for [\"not\", \"xml\"]:Array")
    xml_splitter_action = instantiate_action(Armagh::StandardActions::XMLSplit, @config)
    xml_splitter_action.split(doc)
  end

end
