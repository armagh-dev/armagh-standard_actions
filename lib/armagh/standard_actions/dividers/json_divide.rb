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
require 'armagh/support/json'

module Armagh
  module StandardActions

    class JSONDivide < Armagh::Actions::Divide
      include Armagh::Support::JSON::Divider

      def divide(doc)
        divided_parts(doc, @config) do |part|
          create(part, doc.metadata)
        end
      rescue => e
        notify_dev(e)
      end

      def self.description
        <<~DESCDOC
        This action will take a huge JSON file and break it into smaller JSON files based on a user-defined "divide_target".
        The "divide_target" is presumed to be an Array of elements that makes the file too large to process. The resulting
        smaller files include all of the content before/after the divide target and enough elements of the divide target to
        make the files as large as possible without exceeding the user-defined "size_per_part".
        DESCDOC
      end
    end
  end
end
