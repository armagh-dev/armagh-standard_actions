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

require 'armagh/actions/publish'
require 'armagh/support/field_map'

require 'json'

module Armagh
  module StandardActions
    class JsonPublish < Armagh::Actions::Publish
      include Armagh::Support::FieldMap

      class InvalidJsonError < StandardError; end

      def publish(doc)
        content = JSON.parse(doc.raw)

        if content.is_a? String
          doc.text = content
        else
          content = { 'json' => content }  unless content.is_a? Hash
          doc.content = content
        end

        set_field_map_attrs(doc, @config)
      rescue JSON::ParserError
        raise InvalidJsonError, 'Unable to parse JSON'
      end

      def self.description
        <<~DESCDOC
        This action publishes a JSON document.

        #{Armagh::Support::FieldMap.field_map_description}
        DESCDOC
      end
    end
  end
end
