# frozen_string_literal: true

module CanvasAnnotationDownloader
  class API
    class Assignments < Base
      def find(assignment_id:, course_id:)
        uri = URI("#{api_base_url}/courses/#{course_id}/assignments/#{assignment_id}")
        request(uri)
      end
    end
  end
end
