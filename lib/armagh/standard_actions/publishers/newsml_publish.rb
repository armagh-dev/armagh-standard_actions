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

require 'armagh/actions/publish'
require 'armagh/support/xml'
require 'armagh/support/html'
require 'armagh/support/doc_attr'

require 'time'
require 'tzinfo'

module Armagh
  module StandardActions
    class NewsmlPublish < Armagh::Actions::Publish

      include Armagh::Support::XML
      include Armagh::Support::HTML
      include Armagh::Support::DocAttr

      define_constant name: 'html_nodes', group: 'xml', value: %w(body.content HeadLine SubHeadLine CopyrightLine)

      define_constant name: 'extract_after', group: 'html', value: nil
      define_constant name: 'extract_until', group: 'html', value: nil
      define_constant name: 'exclude', group: 'html', value: nil
      define_constant name: 'ignore_cdata', group: 'html', value: true
      define_constant name: 'force_breaks', group: 'html', value: false
      define_constant name: 'unescape_html', group: 'html', value: true
      define_constant name: 'preserve_hyperlinks', group: 'html', value: true

      def publish(doc)
        xml = doc.raw
        xml_hash = to_hash(xml, @config.xml.html_nodes)
        news_item = get_doc_attr(xml_hash, ['NewsML', 'NewsItem'])
        doc.document_id = get_doc_attr(news_item, ['Identification', 'NewsIdentifier', 'NewsItemId']).strip

        # Comtex does not follow the NewsML standard for timestamp encoding (ISO-8601, which gives zone offset)
        # Instead they use YYYYMMDDTHHMMSS, local to New York.
        begin
          ts_str = get_doc_attr(news_item, ['NewsManagement', 'ThisRevisionCreated']) || get_doc_attr(news_item, ['NewsManagement', 'FirstCreated'])
          if ts_str
            ny_tz = TZInfo::Timezone.get('America/New_York').period_for_local(Time.parse(ts_str)).zone_identifier
            ny_tz_offset = (ny_tz == :EST) ? '-0500' : '-0400'
            doc.document_timestamp = Time.parse("#{ts_str}#{ny_tz_offset}")
          else
            raise
          end
        rescue
          doc.document_timestamp = Time.now.utc
          notify_ops('Timestamp empty or not valid')
        end

        raw_title = get_doc_attr(news_item, ['NewsComponent', 'NewsLines', 'HeadLine']).to_s

        raw_copyright = get_doc_attr(news_item, ['NewsComponent', 'NewsLines', 'CopyrightLine']).to_s

        admin_metadata = get_doc_attr(news_item, ['NewsComponent', 'AdministrativeMetadata'])
        admin_metadata_property = get_doc_attr(admin_metadata, ['Property'])
        property_array = admin_metadata_property.is_a?(Array) ? admin_metadata_property : [admin_metadata_property]
        property_array.each do |elem|
          if elem['attr_FormalName'] == 'SourceCode'
            doc.metadata['source_code'] = elem['attr_Value']
            break
          end
        end
        desc_metadata = get_doc_attr(news_item, ['NewsComponent', 'DescriptiveMetadata'])
        doc.metadata['language'] = get_doc_attr(desc_metadata, ['Language', 'attr_FormalName'])
        data_content = get_doc_attr(news_item, ['NewsComponent', 'ContentItem', 'DataContent'])
        doc.metadata['source'] = get_doc_attr(data_content, ['body', 'body.head', 'distributor']).strip

        body_content = get_doc_attr(data_content, ['body', 'body.content']).to_s

        title, copyright, text = html_to_text(raw_title, raw_copyright, body_content, @config)

        title.strip!
        title.gsub!(/\s+/, ' ')
        copyright.strip!
        text.strip!

        doc.title = title
        doc.copyright = copyright
        doc.text = text
      end

      def self.description
        <<~DESCDOC
          NewsML is an International Press Telecommunication Council (IPTC) open standard
          used by a number of news publishers and aggregators to disseminate
          articles.  This action handles such feeds for you, pulling title, publish date,
          copyright and documentID from appropriate fields in the content.
        DESCDOC
      end
    end
  end
end
