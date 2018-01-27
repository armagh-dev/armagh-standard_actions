# Copyright 2018 Noragh Analytics, Inc.
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
require 'armagh/documents'
require 'armagh/support/ftp'

module Armagh
  module StandardActions

    class FTPCollect < Actions::Collect
      include Armagh::Support::FTP

      def collect
        log_debug "Starting collect with parameters: #{ @config.inspect }"

        collection_results  = {}

        begin

          Armagh::Support::FTP::Connection.open( @config ) do |ftp_connection|

            collection_results = ftp_connection.get_files do | local_filename, attributes, error_string |

              if local_filename

                log_debug "creating doc for collected file #{ local_filename }"

                metadata = {
                  'collected_timestamp' => Time.now.utc
                }

                source = Armagh::Documents::Source.new(
                  type:     'file',
                  filename: local_filename,
                  host:     @config.ftp.host,
                  path:     @config.ftp.directory_path,
                  mtime:    attributes[ 'mtime' ]
                )

                create( collected: local_filename, metadata: metadata, source: source )

              else

                notify_ops( error_string )

              end # if local_filename
            end # ftp_conenction.get_files
          end # Armagh::Support::FTP::Connection.open
        rescue => e

          notify_ops( e )

        ensure

          log_info( "Collected #{ collection_results['collected'] }; Failed collecting #{ collection_results['failed'] }")

        end #begin
      end

      def self.description
        <<~DESCDOC
          This action supports authenticated or anonymous access to a remote FTP server using either the
          passive or active protocol. You can modify defaults for the number of documents collected at one time, and
          for protocol timeouts. You can make your collection more selective by specifying a directory subpath (relative
          to your FTP base path) or a filename pattern, e.g., *.pdf.  All successfully collected documents are
          deleted from the source.
        DESCDOC
      end
    end
  end
end
