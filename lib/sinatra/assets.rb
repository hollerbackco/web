require 'sinatra/base'

module Sinatra
  module Assets
    module Helpers
      def stylesheet_tag(source)
        source = production? ? "#{source}.min.css" : "#{source}.css"

        "<link href=\"#{stylesheet_path(source)}\" rel=\"stylesheet\" />"
      end

      def javascript_tag(source)
        source = production? ? "#{source}.min.js" : "#{source}.js"
        "<script src=\"#{javascript_path(source)}\"></script>"
      end

      def image_tag(source)
        ext = File.extname source
        filename = File.basename(source, ext) + "@2x#{ext}"
        "<img src=\"#{image_path(source)}\" data-at2x=\"#{image_path(filename)}\" />"
      end

      def video_tag(source)
        "<video width=100% controls><source src=\"#{source}\" type=\"video/mp4\"/></video>"
      end
    end
  end
end
