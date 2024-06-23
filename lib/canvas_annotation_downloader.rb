# frozen_string_literal: true

require "dotenv/load"
require_relative "canvas_annotation_downloader/cli"
require_relative "canvas_annotation_downloader/version"

module CanvasAnnotationDownloader
  class Error < StandardError; end

  def self.cli = CLI.call
end
