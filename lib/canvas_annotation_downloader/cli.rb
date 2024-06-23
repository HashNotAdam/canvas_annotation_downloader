# frozen_string_literal: true

require_relative "api"
require_relative "download_annotations"

module CanvasAnnotationDownloader
  class CLI
    private attr_reader :access_token, :canvas_base_url

    def self.call = new.call

    def call
      API.new # validate early that we have API credentials
      DownloadAnnotations.call(course_id:, assignment_id:)
    end

    private

    def course_id
      puts "Enter the course ID: "
      Integer(gets.chomp)
    end

    def assignment_id
      puts "Enter the assignment ID: "
      Integer(gets.chomp)
    end
  end
end
