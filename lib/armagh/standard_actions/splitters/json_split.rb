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

require 'armagh/actions/split'
require 'armagh/support/json'

module Armagh
  module StandardActions
    class JSONSplit < Armagh::Actions::Split
      include Armagh::Support::JSON::Splitter

      def split(doc)
        json_string  = doc.raw
        json_parts   = split_parts(json_string, @config)

        json_parts.each do |part|
          edit do |new_doc|
            new_doc.raw = part
            new_doc.metadata = doc.metadata
          end
        end
      rescue => e
        notify_ops(e)
      end

      def self.description
        <<~DESCDOC
        This action splits up an JSON document with N elements in a given array into N documents,
        where each document contains one element from that array plus the other data from the other nodes
        in the JSON file. You can specify the JSON key of the array with the elements to be split out.
        DESCDOC
      end
    end
  end
end
