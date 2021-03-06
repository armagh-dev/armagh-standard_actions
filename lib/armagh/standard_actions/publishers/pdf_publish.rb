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
require 'armagh/support/pdf'

module Armagh
  module StandardActions
    class PDFPublish < Actions::Publish
      include Support::PDF

      def publish(doc)
        binary = doc.raw

        text, display = pdf_to_text_and_display(binary)

        doc.title ||= doc.source.filename
        doc.document_timestamp ||= doc.source.mtime if doc.source.mtime

        doc.text = text
        doc.display = display
      rescue => e
        if e.class <= PDFError
          notify_ops(e)
        else
          notify_dev(e)
        end
      end

      def self.description
        <<~DESCDOC
        This action publishes the text from PDFs, including pre-version 1.6 (image-based) PDFs using
        Google's tesseract library.  An HMTL
        rendering of the PDF is also stored in the Armagh document, in the display element, as an added bonus.
        DESCDOC
      end
    end
  end
end
