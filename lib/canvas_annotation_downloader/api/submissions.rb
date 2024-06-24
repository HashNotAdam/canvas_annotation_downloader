# frozen_string_literal: true

module CanvasAnnotationDownloader
  class API
    class Submissions < Base
      def in_batches(assignment_id:, course_id:, &block)
        while next_page?
          @page_number += 1

          uri = URI(
            "#{api_base_url}/courses/#{course_id}/assignments/#{assignment_id}/submissions" \
            "?page=#{page_number}&per_page=100"
          )

          request(uri).each { yield _1 }
        end
      ensure
        @page_number = 0
      end
    end
  end
end
