# frozen_string_literal: true

module CanvasAnnotationDownloader
  class API
    class Courses < Base
      def find(course_id:)
        uri = URI("#{api_base_url}/courses/#{course_id}")
        request(uri)
      end
    end
  end
end
