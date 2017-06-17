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

require 'armagh/actions/split'
require 'armagh/support/xml'

module Armagh
  module StandardActions
    class XMLSplit < Armagh::Actions::Split
      include Armagh::Support::XML::Splitter

      class DocumentDataTypeError < StandardError; end

      def split(doc)
        xml = doc.raw
        xmls = split_parts(xml, @config)
        xmls.each do |chunk|
          edit do |d|
            d.raw = chunk
            d.metadata = doc.metadata
          end
        end
      rescue => e
        notify_ops(e)
      end

      def self.description
        <<~DESCDOC
        This action splits up an XML document with N repeated elements into N documents,
        each containing an element.  You can specify the name (not XPATH!) of the repeated 
        element.  You can also identify nodes within the repeated element that contain
        HTML and should not be parsed.
        DESCDOC
      end
    end
  end
end
