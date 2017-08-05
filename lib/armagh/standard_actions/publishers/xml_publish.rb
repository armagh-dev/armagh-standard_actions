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
require 'armagh/support/time_parser'

module Armagh
  module StandardActions
    class XmlPublish < Armagh::Actions::Publish
      include Armagh::Support::XML
      include Armagh::Support::TimeParser

      define_parameter name: 'get_doc_id_from',
                       description: 'XML field/s that contain document ID',
                       type: 'string_array',
                       required: false,
                       group: 'xml_publish'

      define_parameter name: 'get_doc_title_from',
                       description: 'XML field/s that contain document title',
                       type: 'string_array',
                       required: false,
                       group: 'xml_publish'

      define_parameter name: 'get_doc_timestamp_from',
                       description: 'XML field/s that contain document timestamp',
                       type: 'string_array',
                       required: false,
                       group: 'xml_publish'

      define_parameter name: 'timestamp_format',
                       description: 'Format for XML field/s that contain document timestamp',
                       type: 'string',
                       required: false,
                       group: 'xml_publish'

      define_parameter name: 'get_doc_copyright_from',
                       description: 'XML field/s that contain document copyrights',
                       type: 'string_array',
                       required: false,
                       group: 'xml_publish'

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
        if @config.xml_publish.get_doc_id_from && @config.xml_publish.get_doc_id_from.size != 0
          get_doc_attr(xml_hash, @config.xml_publish.get_doc_id_from)
        end
      end

      def title_from_hash(xml_hash)
        if @config.xml_publish.get_doc_title_from && @config.xml_publish.get_doc_title_from.size != 0
          get_doc_attr(xml_hash, @config.xml_publish.get_doc_title_from)
        end
      end

      def timestamp_from_hash(xml_hash)
        if @config.xml_publish.get_doc_timestamp_from && @config.xml_publish.get_doc_timestamp_from.size != 0
          timestamp = get_doc_attr(xml_hash, @config.xml_publish.get_doc_timestamp_from)
          parse_time(timestamp, @config)
        end
      end

      def timestamp_from_doc(doc)
        return nil unless doc.document_timestamp
        parse_time(doc.document_timestamp, @config)
      end

      def copyright_from_hash(xml_hash)
        if @config.xml_publish.get_doc_copyright_from && @config.xml_publish.get_doc_copyright_from.size != 0
          get_doc_attr(xml_hash, @config.xml_publish.get_doc_copyright_from)
        end
      end

      def self.description
        <<~DESCDOC
        This action converts XML into a parallel JSON format and stores it as the published content of the document.
        DESCDOC
      end
    end
  end
end
