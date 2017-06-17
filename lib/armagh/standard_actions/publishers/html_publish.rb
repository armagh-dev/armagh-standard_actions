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
require 'armagh/support/html'

module Armagh
  module StandardActions
    class HTMLPublish < Actions::Publish
      include Support::HTML

      def publish(doc)
        raw_html = doc.raw
        html_pages = raw_html.split(Support::HTML::HTML_PAGE_DELIMITER)

        text_array = []
        html_pages.each {|html| text_array << html_to_text(html, @config)}

        doc.title ||= doc.source.filename || doc.source.url || 'Unknown'
        doc.text = Support::HTML.merge_multiple_pages(text_array)
        doc.text << "\n\nOriginal Content: #{doc.source.url}" if doc.source.url
      rescue HTMLError => e
        notify_ops(e)
      rescue => e
        notify_dev(e)
      end

      def self.description
        <<~DESCDOC
         This action pulls text content out of a webpage, using the w3m utility.  Tags, 
         images, scripts, and style sections are removed.  

         You can limit the section of the page you want to keep through the exclude_before, exclude_after and 
         exclude html options. Patterns are applied to content before it's passed to w3m, so your patterns can include HTML tags.

         Note! CDATA tag content will always be included in the text output. The ignore_cdata option allows you to remove the CDATA directives from your output.
        DESCDOC
      end
    end
  end
end

