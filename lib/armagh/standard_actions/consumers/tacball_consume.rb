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

require 'armagh/actions'
require 'armagh/support/sftp'
require 'armagh/support/tacball'
require 'armagh/support/templating'

module Armagh
  module StandardActions
    class TacballConsume < Actions::Consume
      include Armagh::Support::SFTP
      include Armagh::Support::Tacball
      include Armagh::Support::Templating

      class TacballConsumeError < StandardError; end
      class TACDocPrefixError < TacballConsumeError; end

      define_parameter name: 'template',
                       description: "The template to use for generating both text and html.  If set to #{OPTION_NONE}, will use the text content of the document (if it exists).",
                       type: 'populated_string',
                       required: false,
                       group: 'tacball',
                       default: OPTION_NONE,
                       options: [OPTION_NONE] + Actions.available_templates

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
        orig_file =
          if @config.tacball.attach_orig_file
            fname = doc.source.filename
            fname = random_id if fname.nil? || fname.empty?
            { fname => doc.raw }
          else
            nil
          end

        template_name = @config.tacball.template == OPTION_NONE ? nil : @config.tacball.template
        template_path = Actions.get_template_path(template_name)

        txt_content, html_content = template_content(doc, template_path)

        html_content ||= doc.display || ''
        txt_content  ||= doc.text    || ''

        Armagh::Support::Tacball.create_tacball_file(
          @config,
          docid:         doc.document_id,
          title:         doc.title,
          timestamp:     doc.document_timestamp.to_i,
          txt_content:   txt_content,
          copyright:     doc.copyright,
          html_content:  html_content,
          type:          doc.docspec.type,
          original_file: orig_file,
          logger:        logger
        )
      end

      private def template_content(doc, template_path)
        return nil  unless template_path

        template_root = File.dirname(template_path)

        render_template(template_path, :text, :html, content: doc.content, template_root: template_root)
      end

      def self.description
        <<~DESCDOC
        This action generates tacballs from documents.
        DESCDOC
      end
    end
  end
end
