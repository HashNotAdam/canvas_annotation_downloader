# frozen_string_literal: true

require_relative "api/base"
require_relative "api/assignments"
require_relative "api/submissions"
require_relative "api/submission_attachments"

module CanvasAnnotationDownloader
  class API
    def assignments = Assignments.new

    def courses = Courses.new

    def submissions = Submissions.new

    def submission_attachments = SubmissionAttachments.new
  end
end
