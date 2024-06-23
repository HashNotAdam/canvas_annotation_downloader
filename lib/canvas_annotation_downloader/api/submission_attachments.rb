# frozen_string_literal: true

require_relative "annotated_attachment"

module CanvasAnnotationDownloader
  class API
    class SubmissionAttachments < Base
      def annotated(attachment_details:)
        preview_path = attachment_details.fetch("preview_url")
        AnnotatedAttachment.new(preview_path:).build
      end
    end
  end
end
