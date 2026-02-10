#frozen_string_literal: true
require 'pdf/reader'
require 'json'
require 'tempfile'
require 'securerandom'
module Telegem
  module Plugins
    class FileExtract
      def initialize(bot, file_id, **options)
        @bot = bot
        @file_id = file_id
        @options = {
          auto_delete: true,
          max_file_size: 50 * 1024 * 1024,
          timeout: 60
        }.merge(options)
      @temp_file = nil
      @detected_type = nil
      end 
      def extract
        download_if_needed
        detect_type
        case @detected_type
        when :pdf then extract_pdf
        when :json then extract_json
        when :html then extract_html
        when :txt, :md, :csv then extract_text
        else 
          {
            success: false,
            error: "Unsupported file type: #{@detected_type}"
          }
        end 
      end 
      private 
      def download_if_needed
        return if @temp_file
        @temp_file = Tempfile.new(['telegem_', SecureRandom.hex(6)])
        unless 
          @bot.api.download(@file_id, @temp_file.path)
          raise "Failed to download file with ID #{@file_id}"
        end
        @temp_file.close
      end
      def detect_type
        return @detected_type if @detected_type
        pll = File.read(@temp_file.path, 10) rescue nil
        case pll
        when "%PDF" then @detected_type = :pdf
        when "{", "[" then @detected_type = :json
        when "<!DO", "<ht" then @detected_type = :html
        else 
          ext = File.extname(@temp_file.path).downcase
          @detected_type = case ext
                           when ".txt" then :txt
                           when ".md" then :md
                           when ".csv" then :csv
                           else :unknown
                           end
        end
        @detected_type
      end
      def extract_pdf
        begin 
          reader = PDF::Reader.new(@temp_file.path)
          text = reader.pages.map(&:text).join("\n")
          if text.strip.empty?
            return {
              success: false,
              error: "PDF contains no extractable text"
            }
          else 
          {
            success: true,
            type: :pdf,
            content: text,
            metadata: {
              page_count: reader.page_count,
              info: reader.info
            }
          }
        end 
        rescue => e
          {
            success: false,
            error: "Failed to extract PDF: #{e.message}"
          }
          rescue LoadError
            {
              success: false,
              error: "PDF extraction requires the 'pdf-reader' gem. Please add it to your Gemfile."
            } 
            rescue PDF::Reader::MalformedPDFError => e
              {
                success: false,
                error: "Malformed PDF: #{e.message}"
              } 
            rescue PDF::Reader::UnsupportedFeatureError => e
              {
                success: false,
                error: "Unsupported PDF feature: #{e.message}"
              } 
            rescue PDF::Reader::EncryptedPDFError => e
              {
                success: false,
                error: "Encrypted PDF: #{e.message}"
              } 
            ensure 
              cleanup if @options[:auto_delete]   
        end
      end 
      def extract_json
        begin 
          content = File.read(@temp_file.path)
          data = JSON.parse(content)
          if data.nil? || (data.is_a?(Hash) && data.empty?) || (data.is_a?(Array) && data.empty?)
            return {
              success: false,
              error: "JSON file is empty or contains no data"
            }
          else 
          {
            success: true,
            type: :json,
            content: data,
            metadata: {
              size: content.size,
              keys: data.is_a?(Hash) ? data.keys : nil,
              length: data.is_a?(Array) ? data.length : nil  
          }
        } 
      end 
        rescue JSON::ParserError => e
          {
            success: false,
            error: "Invalid JSON format: #{e.message}"
          }
        ensure 
          cleanup if @options[:auto_delete]   
      end 

      def extract_html
        begin 
          content = File.read(@temp_file.path)
          if content.strip.empty?
            return {
              success: false,
              error: "HTML file is empty"
            }
          end
          {
            success: true,
            type: :html,
            content: content,
            metadata: {
              size: content.size,
              title: content[/<title>(.*?)<\/title>/i, 1]
            }
          }
        rescue => e
          {
            success: false,
            error: "Failed to extract HTML: #{e.message}"
          }
          ensure 
            cleanup if @options[:auto_delete]   
        end
      end
      def extract_text
        begin 
          content = File.read(@temp_file.path)
          if content.strip.empty?
            return {
              success: false,
              error: "Text file is empty"
            }
          end
          {
            success: true,
            type: :text,
            content: content,
            metadata: {
              size: content.size,
              line_count: content.lines.count
            }
          }
        rescue => e
          {
            success: false,
            error: "Failed to extract text: #{e.message}"
          }
          ensure 
            cleanup if @options[:auto_delete]   
        end
      end
      def cleanup
        @temp_file.unlink if @temp_file
        @temp_file = nil
      end
    end
  end
end
end 