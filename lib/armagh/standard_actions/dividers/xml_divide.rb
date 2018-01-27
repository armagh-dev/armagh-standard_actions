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

require 'armagh/actions/divide'
require 'armagh/support/xml'

module Armagh
  module StandardActions

    class XMLDivide < Armagh::Actions::Divide
      include Armagh::Support::XML::Divider

      def divide(doc)
        divided_parts(doc, @config) do |part|
          create(part, doc.metadata)
        end
      rescue => e
        notify_ops(e)
      end

      def self.description
        <<~DESCDOC
        This action will take a huge XML file and break it into smaller XML files, without mangling HTML nodes you
        specify. The breaking is useful when
        you're working on XML documents that have a repeated element.

        Suppose you have an XML document with an inventory.  Embedded in the inventory are many, many complex elements
        named 'inventory_item'. Use this divider to extract the inventory_item elements from the document and write them
        out into one or more files.  Each output file will contain as many inventory_items as can fit within the
        maximum size_per_part byte limit you set.  Save metadata from outside the inventory_item element using the get*
        configuration variables.
        DESCDOC
      end
    end
  end
end
