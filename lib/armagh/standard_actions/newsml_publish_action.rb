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
require 'armagh/support/xml'
require 'armagh/support/html'

require 'time'
require 'tzinfo'
 
module Armagh
  module StandardActions
    class NewsmlPublishAction < Armagh::Actions::Publish

    include Armagh::Support::XML
    include Armagh::Support::HTML
        
      define_parameter name: 'html_nodes',
                       description: 'HTML nodes that need to be kept as-is and not converted into a hash',
                       type: 'string_array',
                       required: false,
                       group: 'xml',
                       default: %w(body.content HeadLine SubHeadLine CopyrightLine)

      def publish(doc)
        xml = doc.raw
        xml_hash = to_hash(xml, @config.xml.html_nodes)
        news_item = dig_first(xml_hash, 'NewsML', 'NewsItem')
        doc.document_id = dig_first(news_item, 'Identification', 'NewsIdentifier', 'NewsItemId').strip
        
        # Comtex does not follow the NewsML standard for timestamp encoding (ISO-8601, which gives zone offset)
        # Instead they use YYYYMMDDTHHMMSS, local to New York.
        begin
          ts_str = dig_first( news_item, 'NewsManagement', 'ThisRevisionCreated' ) || dig_first( news_item, 'NewsManagement', 'FirstCreated' )
          if ts_str
            ny_tz = TZInfo::Timezone.get('America/New_York').period_for_local( Time.parse(ts_str)).zone_identifier
            ny_tz_offset = (ny_tz == :EST) ? '-0500' : '-0400'
            doc.document_timestamp = Time.parse( "#{ts_str}#{ny_tz_offset}" )
          else
            raise
          end
        rescue
          doc.document_timestamp = Time.now.utc
          notify_ops('Timestamp empty or not valid')
        end

        raw_title = dig_first(news_item, 'NewsComponent', 'NewsLines', 'HeadLine').strip
        doc.title = raw_title.empty? ? "Unknown Title: #{doc.document_id}" : html_to_text(raw_title, @config)

        raw_copyright = dig_first(news_item, 'NewsComponent', 'NewsLines', 'CopyrightLine').strip
        doc.copyright = raw_copyright.empty? ? raw_copyright : html_to_text(raw_copyright, @config)

        admin_metadata = dig_first(news_item, 'NewsComponent', 'AdministrativeMetadata')
        admin_metadata_property = dig_first(admin_metadata, 'Property')
        property_array = admin_metadata_property.is_a?(Array) ? admin_metadata_property : [admin_metadata_property]
        property_array.each do |elem|
          if elem['attr_FormalName'] == 'SourceCode'
            doc.metadata['source_code'] = elem['attr_Value']
            break
          end
        end
        desc_metadata = dig_first(news_item, 'NewsComponent', 'DescriptiveMetadata')
        doc.metadata['language'] = dig_first(desc_metadata, 'Language', 'attr_FormalName')
        data_content = dig_first(news_item, 'NewsComponent', 'ContentItem', 'DataContent')
        doc.metadata['source'] = dig_first(data_content, 'body', 'body_head', 'distributor').strip
        doc.text = html_to_text(dig_first(data_content, 'body', 'body_content'), @config).strip
      end
    end
  end
end
