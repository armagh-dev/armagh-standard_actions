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
require 'armagh/support/csv'

module Armagh
  module StandardActions

    class CSVSplitterAction < Actions::Split
      include Armagh::Support::CSV::Splitter

      define_output_docspec 'split_csv', 'documents containing individual records from the input CSV'

      def split(doc)
  
        Armagh::Support::CSV.split_parts(doc, @config ) do |row, errors|
          if errors.empty?
            edit_doc_with_data_from_row(row)
          else
            notify_ops_of_errors(errors)
          end
        end
      end

      private def notify_ops_of_errors(errors)
        errors.each { |e| notify_ops(e) }
      end

      private def edit_doc_with_data_from_row(row)
        edit('split_csv') do |doc|
          doc.raw = row
        end
      end
    end
  end
end
