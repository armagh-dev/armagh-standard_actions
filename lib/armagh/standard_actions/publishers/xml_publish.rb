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
        xml = doc.content['bson_binary'].data
        xml_hash = Armagh::Support::XML.to_hash(xml, @config.xml.html_nodes)
        doc.content = xml_hash
        doc.document_id = Armagh::Support::XML.get_doc_attr(xml_hash, @config.xml.get_doc_id_from) if @config.xml.get_doc_id_from.size != 0
        doc.title = Armagh::Support::XML.get_doc_attr(xml_hash, @config.xml.get_doc_title_from) if @config.xml.get_doc_title_from.size != 0
        doc.document_timestamp = Time.parse(Armagh::Support::XML.get_doc_attr(xml_hash, @config.xml.get_doc_timestamp_from)) if @config.xml.get_doc_timestamp_from.size != 0
        doc.copyright = Armagh::Support::XML.get_doc_attr(xml_hash, @config.xml.get_doc_copyright_from) if @config.xml.get_doc_copyright_from.size != 0
      end

    end
  end
end
