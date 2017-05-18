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

require 'json'

module Armagh
  module StandardActions
    class SFTPConsume < Actions::Consume
      include Armagh::Support::SFTP
      
      define_parameter name: 'transfer_doc_json',
                       description: 'Transfer whole document as JSON instead of just the content',
                       type: 'boolean',
                       default: false,
                       required: true,
                       group: 'sftp'

      def consume(doc)
        host = @config.sftp.host
        port = @config.sftp.port
        path = @config.sftp.directory_path
        log_debug "Transferring file to #{host}:#{port}"

        begin

          if doc.metadata['filename']
            filename = doc.metadata['filename']
          else
            filename = "#{doc.docspec.type}-#{doc.document_id}"
          end
          filename = sanitize_filename filename
          if @config.sftp.transfer_doc_json
            content = doc.to_json
          else
            content = doc.content.to_json
          end
          File.write(filename, content)

          Support::SFTP::Connection.open(@config) do |sftp|
            sftp.put_files do |filename, exception|
              if exception
                if exception.is_a? SFTPError
                  notify_ops(exception)
                else
                  notify_dev(exception)
                end
              else
                log_debug "Transferred #{filename}"
                doc.metadata['sftp_consume'] = {
                    'timestamp' => Time.now.utc,
                    'host' => host,
                    'path' => path,
                    'filename' => filename
                }
              end
            end
          end
          log_info "Transferred 1 document to #{host}:#{port}."
        rescue Support::SFTP::SFTPError => e
          notify_ops e
        end
      end

      private def sanitize_filename(filename)
        filename.gsub(/[^0-9A-z.\-]/, '_')
      end
    end
  end
end