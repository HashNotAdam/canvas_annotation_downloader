# frozen_string_literal: true

require_relative "api"
require_relative "pdf_reader"

module CanvasAnnotationDownloader
  class DownloadAnnotations
    private attr_reader :course_id, :assignment_id, :api

    def self.call(...) = new(...).call

    def initialize(course_id:, assignment_id:)
      @course_id = course_id
      @assignment_id = assignment_id
      @api = API.new
    end

    def call
      puts "\n\nDownloading annotations for course #{course_id} and assignment #{assignment_id}\n\n"

      make_temp_directories
      download_annotated_pdfs.each do |pdf_path|
        download_annotations(pdf_path)
      end
    ensure
      FileUtils.rm_r(DOWNLOAD_DIRECTORY) if Dir.exist?(DOWNLOAD_DIRECTORY)
    end

    private

    TEMP_DIRECTORY = "tmp"
    DOWNLOAD_DIRECTORY = "#{TEMP_DIRECTORY}/downloads"
    ANNOTATION_DIRECTORY = "#{TEMP_DIRECTORY}/annotations"
    private_constant :TEMP_DIRECTORY, :DOWNLOAD_DIRECTORY, :ANNOTATION_DIRECTORY

    def make_temp_directories
      Dir.mkdir(TEMP_DIRECTORY) unless Dir.exist?(TEMP_DIRECTORY)
      Dir.mkdir(DOWNLOAD_DIRECTORY) unless Dir.exist?(DOWNLOAD_DIRECTORY)
      Dir.mkdir(ANNOTATION_DIRECTORY) unless Dir.exist?(ANNOTATION_DIRECTORY)
    end

    def download_annotated_pdfs
      attachments = submission_attachments
      total_attachments = attachments.values.flatten.size
      attachment_index = 0

      attachments.flat_map do |user_id, user_attachments|
        user_attachments.map.with_index do |attachment, user_index|
          puts "Downloading attachment #{attachment_index += 1} of #{total_attachments}"

          file_path = "#{DOWNLOAD_DIRECTORY}/#{course_id}-#{assignment_id}-#{user_id}" \
            "#{"-#{user_index}" if user_attachments.size > 1}" \
            ".pdf"
          File.write(file_path, attachment.download, mode: "wb")

          file_path
        end
      end
    end

    def submission_attachments
      result = Hash.new { |h, k| h[k] = [] }

      api.submissions.in_batches(course_id:, assignment_id:) do |submission|
        submission.fetch("attachments", []).each do |attachment_details|
          submission_attachment = api.submission_attachments.annotated(attachment_details:)
          result[submission.fetch("user_id")] << submission_attachment
        end
      end

      result
    end

    def download_annotations(pdf_path)
      return if pdf_path.nil?

      pdf_reader = PDFReader.new(pdf_path)
      return if pdf_reader.notes.nil?

      file_name = pdf_path.split("/").last.gsub(".pdf", ".txt")
      file_path = "#{ANNOTATION_DIRECTORY}/#{file_name}"
      File.write(file_path, pdf_reader.notes.join("\n"))
    end
  end
end
