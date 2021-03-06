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
require 'armagh/support/word'

module Armagh
  module StandardActions
    class WordPublish < Actions::Publish
      include Support::Word

      def publish(doc)
        binary = doc.raw

        text, display = word_to_text_and_display(binary)

        doc.title ||= doc.source.filename
        doc.document_timestamp ||= doc.source.mtime if doc.source.mtime

        doc.text = text
        doc.display = display
      rescue => e
        if e.class <= WordError
          notify_ops(e)
        else
          notify_dev(e)
        end
      end

      def self.description
        <<~DESCDOC
        This action extracts the text from Microsoft Word&trade; (.doc, .docx, and .docm) files,
        preserving the original formatting as much as possible.  If you have multiple types of Microsoft documents to publish,
        consider the OfficePublish action instead.
        DESCDOC
      end
    end
  end
end
