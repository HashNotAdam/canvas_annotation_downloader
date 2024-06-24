# frozen_string_literal: true

module CanvasAnnotationDownloader
  class API
    class AnnotatedAttachment < Base
      attr_reader :preview_path, :build_requested

      def initialize(preview_path:)
        super()

        @preview_path = preview_path
        @build_requested = false
      end

      def build
        uri = URI("#{canvas_base_url}/#{preview_path}")
        request(uri, format: :plain)

        request(URI(build_url), format: :plain, method: :post)

        self
      end

      def download
        begin
          uri = URI("#{build_url}/is_ready")
          response_body = request(uri)
        end until response_body.fetch(:ready) == true

        uri = URI(build_url)
        request(uri, format: :plain)
      end

      private

      def build_url
        @build_url ||=
          last_response.header["location"].split("/").then do |url|
            url.pop
            url << "annotated.pdf"
            url.join("/")
          end
      end
    end
  end
end
