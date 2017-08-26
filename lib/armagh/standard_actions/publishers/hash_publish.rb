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

module Armagh
  module StandardActions
    class HashPublish < Armagh::Actions::Publish
      include Armagh::Support::FieldMap

      def publish(doc)
        set_field_map_attrs(doc, @config)
      end

      def self.description
        <<~DESCDOC
        This action publishes a document that already has content in proper Hash format.

        #{Armagh::Support::FieldMap.field_map_description}
        DESCDOC
      end
    end
  end
end
