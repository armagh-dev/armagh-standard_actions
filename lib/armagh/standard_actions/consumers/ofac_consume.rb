# Copyright 2016 Noragh Analytics, Inc.
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

require_relative './tacball_consume'
require_relative '../templatable'

module Armagh
  module StandardActions
    class OfacConsume < TacballConsume
      include Templatable

      def filename_from_doc(doc)
        Armagh::Support::Tacball.create_tacball_file(
          @config,
          docid:        doc.document_id,
          title:        doc.title,
          timestamp:    doc.document_timestamp.to_i,
          txt_content:  template_content(doc),
          copyright:    doc.copyright,
          type:         doc.docspec.type,
          logger:       logger
        )
      end

      def template_path(doc)
        entity_type = node_type(doc)
        File.join(template_root, "#{entity_type}_template.erubis")
      end

      private def node_type(doc)
        @node_type ||= get_node_type_from_doc(doc)
      end

      private def get_node_type_from_doc(doc)
        doc.content.dig("sdnList", "sdnEntry", "sdnType").downcase
      end


    end
  end
end
