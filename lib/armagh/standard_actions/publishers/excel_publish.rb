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

require 'armagh/actions/publish'
require 'armagh/support/excel'

module Armagh
  module StandardActions
    class ExcelPublish < Actions::Publish
      include Support::Excel

      def publish(doc)
        binary = doc.raw

        text, display = excel_to_text_and_display(binary)

        doc.title ||= doc.source.filename
        doc.document_timestamp ||= doc.source.mtime if doc.source.mtime

        doc.text = text
        doc.display = display
      rescue => e
        if e.class <= ExcelError
          notify_ops(e)
        else
          notify_dev(e)
        end
      end

      def self.description
        <<~DESCDOC
        This action converts a Microsoft Excel&trade; (.xls, .xlsx, .xlsm, or .xlsb) file
        to text and html equivalents.  If you have multiple types of Microsoft documents to publish,
        consider the OfficePublish action instead.

        The html version replicates spreadsheets as html tables.  Multiple sheets result in multiple tables 
        in the document.  The text version presents the tables as padded text to maintain alignment.  The 
        text version is stored as other published documents store text.  The html version is a bonus parallel 
        element in the document, to make it easier to present and parse a tabular rendering of the sheet when required.

        You might be wondering why tables aren't parsed into useful JSON hashes.  Take a look at 3 different excel
        files written by 3 different people, and you'll understand the challenge in providing anything generic.  If you
        need to maintain the semantics of an excel spreadsheet, you'll need to provide custom actions.
        DESCDOC
      end
    end
  end
end
