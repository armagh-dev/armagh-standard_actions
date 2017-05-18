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
require 'armagh/support/xml'

module Armagh
  module StandardActions
    class XmlPublish < Armagh::Actions::Publish
      include Armagh::Support::XML

      def publish(doc)
        xml = doc.raw
        xml_hash = to_hash(xml, @config.xml.html_nodes)
        doc.content = xml_hash

        doc.document_id        = document_id_from_hash(xml_hash) || doc.document_id
        doc.title              = title_from_hash(xml_hash) || doc.title || doc.source.filename || "unknown"
        doc.document_timestamp = timestamp_from_hash(xml_hash) || timestamp_from_doc(doc) || Time.now
        doc.copyright          = copyright_from_hash(xml_hash)
      end

      def document_id_from_hash(xml_hash)
        if @config.xml.get_doc_id_from && @config.xml.get_doc_id_from.size != 0
          get_doc_attr(xml_hash, @config.xml.get_doc_id_from)
        end
      end

      def title_from_hash(xml_hash)
        if @config.xml.get_doc_title_from && @config.xml.get_doc_title_from.size != 0
          get_doc_attr(xml_hash, @config.xml.get_doc_title_from)
        end
      end

      def timestamp_from_hash(xml_hash)
        if @config.xml.get_doc_timestamp_from && @config.xml.get_doc_timestamp_from.size != 0
          timestamp = get_doc_attr(xml_hash, @config.xml.get_doc_timestamp_from)
          timestamp_format = @config.xml.timestamp_format


          if timestamp_format
            Time.strptime(timestamp, timestamp_format)
          else
            Time.parse(timestamp)
          end
        end
      end

      def timestamp_from_doc(doc)
        return nil unless doc.document_timestamp
        Time.parse(doc.document_timestamp)
      end

      def copyright_from_hash(xml_hash)
        if @config.xml.get_doc_copyright_from && @config.xml.get_doc_copyright_from.size != 0
          get_doc_attr(xml_hash, @config.xml.get_doc_copyright_from)
        end
      end

    end
  end
end
