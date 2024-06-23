# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module CanvasAnnotationDownloader
  class API
    class Base
      private attr_reader :access_token
      private attr_reader :api_base_url
      private attr_reader :canvas_base_url
      private attr_reader :last_response
      private attr_reader :page_number

      def initialize
        @access_token = ENV["ACCESS_TOKEN"]
        @canvas_base_url = ENV["CANVAS_BASE_URL"]
        validate_environment_variables

        @api_base_url = "#{@canvas_base_url}/api/v1"
        @page_number = 0
      end

      private

      def validate_environment_variables
        missing = []
        missing << "ACCESS_TOKEN" if @access_token.nil?
        missing << "CANVAS_BASE_URL" if @canvas_base_url.nil?
        return if missing.empty?

        raise(
          ArgumentError,
          "Missing environment variables: #{missing.join(" and ")}.\n" \
          "Please create .env from .env.example and fill in the missing values."
        )
      end

      def request(uri, format: :json, method: :get)
        req =
          case method
          when :get
            Net::HTTP::Get.new(uri)
          when :post
            Net::HTTP::Post.new(uri)
          else
            raise ArgumentError, "Unsupported HTTP method: #{method}"
          end

        req["Authorization"] = "Bearer #{access_token}"
        response(req, format:)
      end

      def response(req, format:)
        @last_response = Net::HTTP.start(req.uri.hostname, req.uri.port, use_ssl: true) do |http|
          http.request(req)
        end

        response_body = last_response.body
        response_body = JSON.parse(response_body) if format == :json
        if last_response.is_a?(Net::HTTPSuccess) || last_response.is_a?(Net::HTTPFound)
          return response_body
        end

        raise error_messages(response_body:, format:)
      end

      def error_messages(response_body:, format:)
        return response_body unless format == :json
        return response_body unless response_body.key?("errors")

        response_body.fetch("errors").
          map { "#{_1.fetch("error_code")}: #{_1.fetch("message")}" }.
          join("\n")
      end

      def next_page?
        return true if page_number.zero?

        last_response.header["link"].include?("rel=\"next\"")
      end
    end
  end
end
