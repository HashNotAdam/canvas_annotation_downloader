# frozen_string_literal: true

require "axlsx"

require_relative "api"
require_relative "pdf_reader"

module CanvasAnnotationDownloader
  class DownloadAnnotations
    private attr_reader :course_id, :assignment_id, :api, :submission_groups

    def self.call(...) = new(...).call

    def initialize(course_id:, assignment_id:)
      @course_id = course_id
      @assignment_id = assignment_id

      @api = API.new
      @submission_groups = []
    end

    def call
      puts "\n\nDownloading annotations for course #{course_id} and assignment #{assignment_id}\n\n"

      make_temp_directories
      load_submissions
      download_annotated_pdfs
      download_annotations
      generate_summary_document
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

    def load_submissions
      api.submissions.in_batches(course_id:, assignment_id:) do |submission|
        @submission_groups << { submission: submission }
      end
    end

    def download_annotated_pdfs
      load_submission_attachments
      total_attachments = submission_groups.sum { _1.fetch(:attachments).size }
      attachment_index = 0

      submission_groups.flat_map do |submission_group|
        user_attachments = submission_group.fetch(:attachments)
        user_attachments.map.with_index do |attachment, user_index|
          puts "Downloading attachment #{attachment_index += 1} of #{total_attachments}"

          user_id = submission_group.fetch(:submission).fetch(:user_id)
          pdf_path = "#{DOWNLOAD_DIRECTORY}/#{course_id}-#{assignment_id}-#{user_id}" \
            "#{"-#{user_index}" if user_attachments.size > 1}" \
            ".pdf"
          File.write(pdf_path, attachment.fetch(:submission_attachment).download, mode: "wb")

          attachment[:pdf_path] = pdf_path
        end
      end
    end

    def load_submission_attachments
      submission_groups.each do |submission_group|
        submission_group[:attachments] = []

        submission_group.fetch(:submission).fetch(:attachments, []).each do |attachment_details|
          submission_attachment = api.submission_attachments.annotated(attachment_details:)
          submission_group[:attachments] << { submission_attachment: }
        end
      end
    end

    def download_annotations
      submission_groups.each do |submission_group|
        submission_group.fetch(:attachments).each do |attachment|
          pdf_path = attachment.fetch(:pdf_path)
          pdf_reader = PDFReader.new(pdf_path)
          return if pdf_reader.notes.nil?

          file_name = pdf_path.split("/").last.gsub(".pdf", ".txt")
          text_path = "#{ANNOTATION_DIRECTORY}/#{file_name}"
          File.write(text_path, pdf_reader.notes.join("\n"))

          attachment[:text_path] = text_path
        end
      end
    end

    def generate_summary_document
      xlsx = Axlsx::Package.new
      workbook = xlsx.workbook
      worksheet = workbook.add_worksheet do |sheet|
        sheet.add_row(["User ID", "Student ID", "Assignment grade", "Annotations"])
      end

      add_annotations_to_worksheet(worksheet)

      FileUtils.rm(annotations_file_path) if File.exist?(annotations_file_path)
      xlsx.serialize(annotations_file_path)
    end

    def add_annotations_to_worksheet(worksheet)
      index = 0
      submission_groups.each do |submission_group|
        user_id = submission_group.fetch(:submission).fetch(:user_id)
        grade = submission_group.fetch(:submission).fetch(:grade)
        annotations = submission_group.fetch(:attachments)

        annotations.each do |annotation|
          text_path = annotation.fetch(:text_path)
          relative_text_path = text_path.gsub(%r{^tmp/}, "./")

          row = worksheet.add_row([user_id, nil, grade, relative_text_path])
          worksheet.add_hyperlink(location: relative_text_path, ref: row.last.r)
        end
      end
    end

    def annotations_file_path
      "#{TEMP_DIRECTORY}/annotations-#{course_id}-#{assignment_id}.xlsx"
    end
  end
end
