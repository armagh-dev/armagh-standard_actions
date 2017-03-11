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
require 'armagh/support/http'
require 'armagh/support/html'
require 'armagh/support/string_digest'

module Armagh
  module StandardActions
    class HTTPCollectAction < Actions::Collect

      include Armagh::Support::HTTP

      define_parameter name: 'deduplicate_content', description: 'Prevent collection when the content of the URL has not changed since last collect.', type: 'boolean', required: true, default: false

      define_output_docspec 'http_collected_document', 'All documents collected from this web source in raw form'

      def collect
        log_debug "Collecting from '#{@config.http.url}'"

        begin
          http = Armagh::Support::HTTP::Connection.new(@config)
          response = http.fetch

          metadata = {
              'url' => @config.http.url,
              'collected_timestamp' => Time.now.utc,
          }

          source = Armagh::Documents::Source.new(type: 'url', url: @config.http.url)

          type = Armagh::Support::HTTP.extract_type(response.first['head'])
          source.encoding = type['encoding'] if type['encoding']
          source.mime_type = type['type'] if type['type']

          content = response.collect{|r| r['body']}.join(Armagh::Support::HTML::HTML_PAGE_DELIMITER)

          with_locked_action_state do |state|
            md5 = Armagh::Support::StringDigest.md5(content)

            if @config.http_collect_action.deduplicate_content && state.content[@config.http.url] == md5
              log_info "Content of #{@config.http.url} has not changed since last collection."
            else
              state.content[@config.http.url] = md5
              create(collected: content, metadata: metadata, docspec_name: 'http_collected_document', source: source)
              log_info "Collected 1 document from '#{@config.http.url}'"
            end
          end
        rescue HTTPError => e
          notify_ops e
        end
      end
    end
  end
end
