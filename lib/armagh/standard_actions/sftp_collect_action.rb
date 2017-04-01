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

module Armagh
  module StandardActions
    class SFTPCollectAction < Actions::Collect
      include Armagh::Support::SFTP

      def collect

        host = @config.sftp.host
        port = @config.sftp.port
        path = @config.sftp.directory_path

        log_debug "Collecting from #{host}:#{port}"
        num_collected = 0

        begin
          Armagh::Support::SFTP::Connection.open(@config) do |sftp|
            sftp.get_files do |filename, attributes, exception|
              if exception
                if exception.is_a? SFTPError
                  notify_ops exception
                else
                  notify_dev exception
                end
              else
                source = Armagh::Documents::Source.new(type: 'file', filename: filename, path: path, host: host, mtime: attributes['mtime'])

                metadata = {
                    'collected_timestamp' => Time.now.utc,
                }
                create(collected: filename, metadata: metadata, source: source)
                log_debug("Collected #{filename}")
                num_collected += 1
              end
            end
          end
          log_info "Collected #{num_collected} documents from #{host}:#{port}."
        rescue SFTPError => e
          notify_ops e
        end
      end
    end
  end
end
