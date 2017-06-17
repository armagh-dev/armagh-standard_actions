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

module Armagh
  module StandardActions
    class TacballConsume < Actions::Consume
      include Armagh::Support::SFTP
      include Armagh::Support::Tacball

      class TacballConsumeError < StandardError; end
      class TACDocPrefixError < TacballConsumeError; end

      raise TACDocPrefixError, 'The environment variable ARMAGH_TAC_DOC_PREFIX is not set but is required.' unless ENV['ARMAGH_TAC_DOC_PREFIX']

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
        puts e.inspect
        notify_dev(e)
      end

      def filename_from_doc(doc)
        Armagh::Support::Tacball.create_tacball_file(
          @config,
          docid:        doc.document_id,
          title:        doc.title,
          timestamp:    doc.document_timestamp.to_i,
          txt_content:  doc.text,
          copyright:    doc.copyright,
          html_content: doc.display,
          type:         doc.docspec.type,
          logger:       logger
        )
      end

      def self.description
        <<~DESCDOC
        This action generates tacballs from documents.  The publish action in the workflow is
        responsible for correctly preparing the searchable and displayable text.
        DESCDOC
      end

    end
  end
end
