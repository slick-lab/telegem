require 'json'
require 'pdf/reader'

module Telegem
  module Plugins
    class FileExtractor
      def initialize(bot, file_id, **options)
        @bot = bot
        @file_id = file_id
        @options = {
          timeout: 15,
          auto_delete: true,
          file_type: nil
        }.merge(options)
          unless file_id.is_a?(string) && file_id.length.between?(34, 100)
          raise ArgumentError, "invalid telegram file id format" 
        file_path = "temp/#{@file_id}"
        download_file(file_path)
      end

      def download_file(file_path)
        if @options[:file_type] == :pdf
          extract_pdf(file_path)
        elsif @options[:file_type] == :json
          extract_json(file_path)
        elsif @options[:file_type] == :html
          extract_html(file_path)
        elsif @options[:file_type] == :txt
          extract_text(file_path)
        else
          { error: "unsupported file type" }
        end
      end

      def extract_pdf(file_path)
        begin
          file_info = @bot.api.call('getFile'. file_id: file_id)
           if file_info['file_size'].to_i > (60 * 1024 * 1024)
            raise "file to large (#{file_info['file_size']} > 60mb)"
           end 
          @bot.api.download(@file_id, "#{file_path}.pdf")
          reader = PDF::Reader.new("#{file_path}.pdf")
          text = reader.pages.map(&:text).join("\n").strip

          if text.empty?
            { error: "pdf is empty" }
          else
            result = {
              success: true,
              content: text,
              pages: reader.page_count,
            }
            File.delete("#{file_path}.pdf") if @options[:auto_delete]
            result
          end
        rescue PDF::Reader::MalformedPDFError
          { error: "malformed pdf format" }
        rescue PDF::Reader::EncryptedPDFError
          { error: "encrypted pdf" }
        rescue => e
          { error: "pdf processing failed #{e.message}" }
        ensure
          File.delete("#{file_path}.pdf") if @options[:auto_delete] && File.exist?("#{file_path}.pdf")
        end
      end

      def extract_json(file_path)
        file_info = @bot.api.call('getFile'. file_id: file_id)
           if file_info['file_size'].to_i > (60 * 1024 * 1024)
            raise "file to large (#{file_info['file_size']} > 60mb)"
           end 
        @bot.api.download(@file_id, "#{file_path}.json")
        json_data = JSON.parse(File.read("#{file_path}.json"))
        if File.exist?("#{file_path}.json")
          {
            success: true,
            content: json_data
          }
        else
          {
            error: "no json file"
          }
        end
      end

      def extract_html(file_path)
        file_info = @bot.api.call('getFile'. file_id: file_id)
           if file_info['file_size'].to_i > (60 * 1024 * 1024)
            raise "file to large (#{file_info['file_size']} > 60mb)"
           end 
        destination = "#{file_path}.html"
        @bot.api.download(@file_id, destination)
        html = File.read(destination)
        if html.empty?
          {
            error: "html content is empty"
          }
        else
          {
            success: true,
            content: html
          }
        end
      rescue => e
        {
          error: "error #{e.message}"
        }
      end
    end
  end
end