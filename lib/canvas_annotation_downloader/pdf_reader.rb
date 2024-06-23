# frozen_string_literal: true

require "pdf-reader"

module CanvasAnnotationDownloader
  class PDFReader
    attr_reader :pdf_path, :pdf

    def initialize(pdf_path)
      @pdf_path = pdf_path

      @pdf = PDF::Reader.new(pdf_path)
    end

    def notes
      @notes ||=
        pdf.pages.map do |page|
          notes_on_page(page)&.filter_map { _1[:Contents] }
        end
    end

    private

    def objects
      @objects ||= pdf.objects
    end

    def notes_on_page(page)
      annotations_on_page(page).find_all { |a| note?(a) }
    end

    def annotations_on_page(page)
      references = (page.attributes[:Annots] || [])
      lookup_all(references).flatten
    end

    def lookup_all(references)
      references = *references
      references.map { |reference| lookup(reference) }
    end

    def lookup(reference)
      object = objects[reference]
      return object unless object.is_a?(Array)

      lookup_all(object)
    end

    def note?(object)
      object[:Type] == :Annot && [:Text, :FreeText].include?(object[:Subtype])
    end
  end
end
