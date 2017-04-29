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

require 'armagh/actions/publish'
require 'armagh/support/excel'
require 'armagh/support/pdf'
require 'armagh/support/powerpoint'
require 'armagh/support/word'

module Armagh
  module StandardActions
    class OfficePublish < Actions::Publish
      include Support::Excel
      include Support::PDF
      include Support::PowerPoint
      include Support::Word

      class UnsupportedDocumentError < StandardError; end

      DOC_TYPES = {
        excel: [
          '.xls',  'application/vnd.ms-excel',
          '.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          '.xlsm', 'application/vnd.ms-excel.sheet.macroenabled.12',
          '.xlsb', 'application/vnd.ms-excel.sheet.binary.macroenabled.12'],
        pdf: [
          '.pdf',  'application/pdf'],
        powerpoint: [
          '.ppt',  'application/vnd.ms-powerpoint',
          '.pptx', 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
          '.pptm', 'application/vnd.ms-powerpoint.presentation.macroenabled.12',
          '.ppsx', 'application/vnd.openxmlformats-officedocument.presentationml.slideshow',
          '.ppsm', 'application/vnd.ms-powerpoint.slideshow.macroenabled.12',
          '.sldx', 'application/vnd.openxmlformats-officedocument.presentationml.slide',
          '.sldm', 'application/vnd.ms-powerpoint.slide.macroenabled.12'],
        word: [
          '.doc',  'application/msword',
          '.docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          '.docm', 'application/vnd.ms-word.document.macroenabled.12']
      }

      def publish(doc)
        binary   = doc.raw
        doc_type = (doc.source.mime_type || File.extname(doc.source.filename)).to_s.downcase.strip
        raise UnsupportedDocumentError, 'Unable to determine document type' if doc_type.empty?

        text, display =
          if DOC_TYPES[:excel].include?(doc_type)
            doc.metadata['type'] = 'Excel'
            excel_to_text_and_display(binary)
          elsif DOC_TYPES[:pdf].include?(doc_type)
            doc.metadata['type'] = 'PDF'
            pdf_to_text_and_display(binary)
          elsif DOC_TYPES[:powerpoint].include?(doc_type)
            doc.metadata['type'] = 'PowerPoint'
            powerpoint_to_text_and_display(binary)
          elsif DOC_TYPES[:word].include?(doc_type)
            doc.metadata['type'] = 'Word'
            word_to_text_and_display(binary)
          else
            raise UnsupportedDocumentError, "Unsupported document #{doc.source.filename}"
          end

        doc.title ||= doc.source.filename if doc.source.filename
        doc.document_timestamp ||= doc.source.mtime if doc.source.mtime

        doc.text = text
        doc.display = display
      rescue => e
        if e.class == UnsupportedDocumentError ||
           e.class <= ExcelError ||
           e.class <= PDFError ||
           e.class <= PowerPointError ||
           e.class <= WordError
          notify_ops(e)
        else
          notify_dev(e)
        end
      end

    end
  end
end
