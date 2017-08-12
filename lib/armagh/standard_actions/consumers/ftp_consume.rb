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
require 'armagh/support/ftp'

require 'json'

module Armagh
  module StandardActions
    class FTPConsume < Actions::Consume
      include Armagh::Support::FTP

      INVALID_FILENAME_CHARACTERS = /[^0-9A-z.\-]/

      define_parameter name:        'transfer_doc_json',
                       description: 'Transfer whole document as JSON instead of just the content',
                       type:        'boolean',
                       default:     false,
                       required:    true,
                       group:       'ftp'

      def consume(doc)
        host = @config.ftp.host
        port = @config.ftp.port
        path = @config.ftp.directory_path
        log_debug "Transferring file to #{host}:#{port}/#{path}"

        filename = filename_from_doc(doc)
        content  = content_from_doc(doc)

        File.write(filename, content)

        Connection.open(@config) do |ftp|
          ftp.put_files do |filename, exception|
            if exception
              case exception
              when Armagh::Support::FTP::PermissionsError
                notify_ops(exception)
              else
                notify_dev(exception)
              end
            else
              log_debug "Transferred #{filename}"
              doc.metadata['ftp_consume'] = {
                  'timestamp' => Time.now.utc,
                  'host' => host,
                  'path' => path,
                  'filename' => filename
              }
            end
          end
        end

        log_info "Transferred 1 document to #{host}:#{port}/#{path}."

        rescue Armagh::Support::FTP::ConnectionError => e
          notify_ops e
        rescue Armagh::Support::FTP::UnhandledError => e
          notify_ops e
      end

      private def sanitize_filename(filename)
        filename.gsub(INVALID_FILENAME_CHARACTERS, '_')
      end

      private def filename_from_doc(doc)
        filename = doc.metadata['filename'] || "#{doc.docspec.type}-#{doc.document_id}"
        sanitize_filename(filename)
      end

      private def content_from_doc(doc)
        @config.ftp.transfer_doc_json ? doc.to_json : doc.content.to_json
      end

    end
  end
end
