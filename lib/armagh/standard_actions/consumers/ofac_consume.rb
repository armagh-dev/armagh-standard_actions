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

require 'armagh/actions'
require 'armagh/support/sftp'
require 'armagh/support/tacball'
require 'armagh/support/templating'

module Armagh
  module StandardActions
    class OfacConsume < Actions::Consume
      include Armagh::Support::SFTP
      include Armagh::Support::Tacball
      include Armagh::Support::Templating

      def consume(doc)

        filename = filename_from_doc(doc)

        Support::SFTP::Connection.open(@config) do |sftp|
          sftp.put_file(filename, @config.tacball.feed)
        end
        log_debug "Transferred #{filename}"
        doc.metadata['tacball_consume'] = {
          'timestamp' => Time.now.utc,
          'host' => @config.sftp.host,
          'path' => @config.sftp.directory_path,
          'filename' => filename
        }
      rescue Support::SFTP::SFTPError => e
        notify_ops(e)
      rescue => e
        notify_dev(e)
      end

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

      private def template_content(doc)
        render_template(template_path(doc), :text, entity: doc.content)
      end

      private def template_path(doc)
        entity_type = node_type(doc)
        File.join(template_root, "#{entity_type}_template.erubis")
      end

      private def node_type(doc)
        @node_type ||= get_node_type_from_doc(doc)
      end

      private def template_root
        armagh_path = File.join(File.expand_path("../../..", __FILE__))
        File.join(armagh_path, "templates", workflow_name)
      end

      def partials_root
        File.join(template_root, "partials")
      end

      private def get_node_type_from_doc(doc)
        doc.content.dig("sdnList", "sdnEntry", "sdnType").downcase
      end

      def self.description
        <<~DESCDOC
          This action generates tacballs from OFAC records pulled into Armagh.
        DESCDOC
      end
    end
  end
end
