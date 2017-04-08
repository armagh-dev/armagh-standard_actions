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
require 'armagh/support/rss'
require 'armagh/support/html'
require 'armagh/support/string_digest'

module Armagh
  module StandardActions
    class RSSCollectAction < Actions::Collect

      include Armagh::Support::RSS

      def collect
        log_debug "Collecting from '#{@config.http.url}'"

        docs_collected = 0

        begin
          with_locked_action_state do |state|
            collect_rss(@config, state, logger: logger) do |channel, item, content_array, type, timestamp, exception|
              if exception
                if exception.is_a?(RSSError) || exception.is_a?(HTTPError)
                  notify_ops exception
                else
                  notify_dev exception
                end
              else
                metadata = {
                  'rss_url' => @config.http.url,
                  'collected_timestamp' => Time.now.utc,
                }

                source = Armagh::Documents::Source.new(type: 'url', mtime: timestamp)

                source.url = item[@config.rss.link_field] || @config.http.url
                source.encoding = type['encoding'] if type['encoding']
                source.mime_type = type['type'] if type['type']

                content_str = content_array.join(Armagh::Support::HTML::HTML_PAGE_DELIMITER)

                if @config.rss.passthrough
                  metadata['item'] = item
                  metadata['channel'] = channel
                  create(collected: content_str,
                         metadata: metadata,
                         source: source)
                else
                  item_doc_id = item['guid'] if item['guid'] && !item['guid'].empty?
                  item_doc_id ||= item['id'] if item['id'] && !item['id'].empty?
                  item_doc_id ||= item['link'] if item['link'] && !item['link'].empty?
                  item_doc_id ||= item['title'] if item['title'] && !item['title'].empty?
                  if item_doc_id
                    id = item_doc_id ? Armagh::Support::StringDigest.md5(@config.action.name + item_doc_id) : nil
                  else
                    notify_ops("Document does not contain a 'guid', 'id', 'link' or 'title' fields")
                  end

                  title = CGI.unescape_html(item['title']) if item['title']
                  create(document_id: id,
                         collected: content_str,
                         metadata: metadata,
                         source: source,
                         document_timestamp: timestamp,
                         title: title)
                end

                docs_collected += 1
              end
            end
          end
        rescue RSSError, HTTPError => e
          notify_ops e
        end

        log_info "Collected #{docs_collected} documents from '#{@config.http.url}'"
      end
    end
  end
end
