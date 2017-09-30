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
require 'armagh/support/html'

module Armagh
  module StandardActions
    class MovieTacballConsume < Actions::Consume
      include Armagh::Support::SFTP
      include Armagh::Support::Tacball
      include Armagh::Support::HTML

      class MovieTacballConsumeError < StandardError; end
      class TACDocPrefixError < MovieTacballConsumeError; end

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
        raise MovieTacballConsumeError.new('Movie JSON document must have \'html_content\'')  unless doc.content['html_content']

        orig_file =
          if @config.tacball.attach_orig_file
            fname = doc.source.filename
            fname = random_id if fname.nil? || fname.empty?
            { fname => doc.raw }
          else
            nil
          end
        Armagh::Support::Tacball.create_tacball_file(
          @config,
          docid:         doc.document_id,
          title:         doc.title,
          timestamp:     doc.document_timestamp.to_i,
          txt_content:   doc.content['txt_content'] || html_to_text(doc.content['html_content'], @config),
          copyright:     doc.copyright,
          html_content:  doc.content['html_content'],
          type:          doc.docspec.type,
          original_file: orig_file,
          logger:        logger
        )
      end

      def self.description
        <<~DESCDOC
        This action generates tacballs from Movie JSON documents, which must contain 'html_content' and may contain 'txt_content'.
        DESCDOC
      end

    end
  end
end
