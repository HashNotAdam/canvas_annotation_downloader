# frozen_string_literal: true

require_relative "lib/canvas_annotation_downloader/version"

Gem::Specification.new do |spec|
  spec.name = "CanvasAnnotationDownloader"
  spec.version = CanvasAnnotationDownloader::VERSION
  spec.authors = ["Adam Rice"]
  spec.email = ["development@hashnotadam.com"]

  spec.summary = "Download all annotations from submissions to a Canvas assignment"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ Gemfile])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "caxlsx", "< 5.0"
  spec.add_dependency "dotenv", "< 4.0"
  spec.add_dependency "pdf-reader", "< 3.0"
end
