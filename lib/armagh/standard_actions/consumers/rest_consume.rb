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

require 'json'

module Armagh
  module StandardActions
    class RESTConsume < Actions::Consume
      include Armagh::Support::HTTP

      define_constant name: 'method', value: Armagh::Support::HTTP::POST, group: 'http'
      define_constant name: 'fields', value: {}, group: 'http'
      define_constant name: 'host_whitelist', value: nil, group: 'http'
      define_constant name: 'host_blacklist', value: nil, group: 'http'
      define_constant name: 'filetype_whitelist', value: nil, group: 'http'
      define_constant name: 'filetype_blacklist', value: nil, group: 'http'
      define_constant name: 'mimetype_whitelist', value: nil, group: 'http'
      define_constant name: 'mimetype_blacklist', value: nil, group: 'http'
      define_constant name: 'multiple_pages', value: false, group: 'http'
      define_constant name: 'max_pages', value: 1, group: 'http'
      define_constant name: 'follow_redirects', value: false, group: 'http'
      define_constant name: 'allow_https_to_http', value: false, group: 'http'

      JSON_HEADER = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }

      def consume(doc)
        log_debug "Posting #{doc.docspec}: #{doc.document_id} to #{@config.http.url}."

        http = Armagh::Support::HTTP::Connection.new(@config, json_client: true)
        http.fetch(fields: doc.to_hash, headers: JSON_HEADER)
      rescue HTTPError => e
        puts e
        notify_ops e
      end

      def self.description
        <<~DESCDOC
          This action POSTs a published document in JSON format to an external REST endpoint for additional processing by external tools.
          It supports basic- or certificate-authenticated operations, authenticated and unauthenticated proxy access, 
          security features controlling whether redirects are followed and whether https-to-http redirect is allowed.
        DESCDOC
      end
    end
  end
end
