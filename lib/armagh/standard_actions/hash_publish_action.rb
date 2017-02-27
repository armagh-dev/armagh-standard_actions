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

module Armagh
  module StandardActions
    class HashPublishAction < Armagh::Actions::Publish

      define_parameter name:        'id_field',
                       description: 'Field to use for document ID',
                       prompt:      'A field found by traversing the content hash, e.g. ["account_number"]',
                       type:        'string_array',
                       required:    false,
                       group:       'hash_publish_action'

      define_parameter name:        'timestamp',
                       description: 'Field to use for document timestamp',
                       prompt:      'A field found by traversing the content hash, e.g. ["saved_at"]',
                       type:        'string_array',
                       required:    false,
                       group:       'hash_publish_action'

      define_parameter name:        'copyright',
                       description: 'Field to use for document copyright',
                       prompt:      'A field found by traversing the content hash, e.g. ["copyright_notice"]',
                       type:        'string_array',
                       required:    false,
                       group:       'hash_publish_action'

      define_parameter name:        'title',
                       description: 'Field to use for document title',
                       prompt:      'A field found by traversing the content hash, e.g. ["filename"]',
                       type:        'string_array',
                       required:    false,
                       group:       'hash_publish_action'

      def publish(doc)
        id_field        = format_field(@config.hash_publish_action.id_field)
        timestamp_field = format_field(@config.hash_publish_action.timestamp)
        copyright_field = format_field(@config.hash_publish_action.copyright)
        title_field     = format_field(@config.hash_publish_action.title)

        if id_field
          id =  doc.content.dig(id_field)
        else
          # KN: what's our fallback for id_field?
        end

        if timestamp_field
          timestamp =  doc.content.dig(timestamp_field)
        else
          timestamp = doc.source.mtime
        end

        if copyright_field
          copyright =  doc.content.dig(copyright_field)
        else
          doc_metadata = doc.metadata.first
          copyright = doc_metadata['copyright']
        end

        if title_field
          title =  doc.content.dig(title_field)
        else
          title = doc.source.filename
        end

        doc.document_id        = id
        doc.title              = title
        doc.copyright          = copyright
        doc.document_timestamp = timestamp
      end

      private def format_field(field)
        field.map(&:strip).join(",")
      end


    end
  end
end
