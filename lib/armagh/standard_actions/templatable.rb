require 'armagh/support/templating'

module Armagh
  module StandardActions
    module Templatable
      include Armagh::Support::Templating

      def self.included(base)
        base.class_eval do
          def partials_root
            File.join(template_root, "partials")
          end

          private def template_root
            armagh_path = File.join(File.expand_path("../..", __FILE__))
            File.join(armagh_path, "templates", workflow_name)
          end

          private def workflow_name
            self.class.to_s.split("::").last.match(/(\w+)Consume/).captures.first.downcase
          end

          private def template_content(doc)
            render_template(template_path(doc), :text, entity: doc.content)
          end

          # returns the file path for the template that corresponds to the document passed in as an argument
          private def template_path(doc)
            raise "Instance method #template_path(doc) must be implemented by any classes that include the Templatable module"
          end

        end
      end

    end
  end
end
