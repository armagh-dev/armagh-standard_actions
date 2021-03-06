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

module Armagh
  module StandardActions
    class TextPublish < Armagh::Actions::Publish

      def publish(doc)
        text = doc.raw.to_s

        doc.title              ||= doc.source.filename
        doc.document_timestamp ||= doc.source.mtime

        doc.text = text
      end

      def self.description
        <<~DESCDOC
        This action simply publishes the text already in the document, setting the document title and timestamp to the
        original file's filename and mtime (if applicable).
        DESCDOC
      end
    end
  end
end
