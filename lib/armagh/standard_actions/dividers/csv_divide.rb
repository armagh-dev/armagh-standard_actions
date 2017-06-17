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

require 'armagh/actions/divide'
require 'armagh/support/csv'

module Armagh
  module StandardActions

    class CSVDivide < Armagh::Actions::Divide
      include Armagh::Support::CSV::Divider
      
      def divide(doc)
        Armagh::Support::CSV.divided_parts( doc, @config) do |part|
          create(part, {})
        end
      end

      def self.description
        <<~DESCDOC
        This action will take a huge CSV file and break it into smaller CSV files.  Headers are preserved
        in each smaller file.  You can configure CSV format parameters, and specify the approximate maximum size of
        a smaller file.  The action will find the closest record delimiter ("row_sep") to your maximum size and break the file there.
        DESCDOC
      end
    end
  end
end
