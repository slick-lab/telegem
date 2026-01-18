require 'open-uri'
require 'tempfile'
require 'pdf-reader'
require 'docx'

module Telegem
  module Plugins
    class FileExtractor
      SUPPORTED_TYPES = {
        pdf: 'application/pdf',
        docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        txt: 'text/plain',
        csv: 'text/csv',
        html: 'text/html',
        rtf: 'application/rtf',
        odt: 'application/vnd.oasis.opendocument.text'
      }
      
      def initialize(**options)
        @options = {
          max_size: 10 * 1024 * 1024,
          timeout: 30,
          cache: true
        }.merge(options)
        
        @cache = Telegem::Session::MemoryStore.new
      end
      
      def call(ctx, next_middleware)
        ctx.define_singleton_method(:extract_file_text) do |file_id = nil, **opts|
          extract_from_context(self, file_id, opts)
        end
        
        ctx.define_singleton_method(:file_content) do
          @_file_content
        end
        
        ctx.define_singleton_method(:file_metadata) do
          @_file_metadata
        end
        
        next_middleware.call(ctx)
      end
      
      class << self
        def extract_from_context(ctx, file_id = nil, **options)
          message = ctx.update.message
          return nil unless message
          
          file_info = find_file_info(message, file_id)
          return nil unless file_info
          
          return file_info[:content] if file_info[:type] == :text
          
          file_path = download_file(ctx.bot.api, file_info[:file_id], options)
          return nil unless file_path
          
          text = extract_text(file_path, file_info[:type])
          
          if options.fetch(:cache, true)
            ctx.instance_variable_set(:@_file_content, text)
            ctx.instance_variable_set(:@_file_metadata, file_info)
          end
          
          text
        end
        
        private
        
        def find_file_info(message, file_id)
          return { file_id: file_id, type: :unknown } if file_id
          
          if message.document
            mime = message.document.mime_type || 'application/octet-stream'
            type = SUPPORTED_TYPES.key(mime) || :unknown
            { file_id: message.document.file_id, type: type, mime: mime, name: message.document.file_name }
          elsif message.photo&.any?
            { file_id: message.photo.last.file_id, type: :image, mime: 'image/jpeg' }
          elsif message.video
            { file_id: message.video.file_id, type: :video, mime: message.video.mime_type }
          elsif message.audio
            { file_id: message.audio.file_id, type: :audio, mime: message.audio.mime_type }
          elsif message.voice
            { file_id: message.voice.file_id, type: :audio, mime: 'audio/ogg' }
          elsif message.text
            { type: :text, content: message.text }
          end
        end
        
        def download_file(api, file_id, options)
          file = api.call('getFile', file_id: file_id)
          return nil unless file && file['ok']
          
          file_path = file['result']['file_path']
          url = "https://api.telegram.org/file/bot#{api.token}/#{file_path}"
          
          temp_file = Tempfile.new(['telegem', File.extname(file_path)])
          
          URI.open(url, read_timeout: options[:timeout] || 30) do |remote|
            temp_file.binmode
            temp_file.write(remote.read)
          end
          
          temp_file.close
          temp_file.path
        rescue => e
          nil
        end
        
        def extract_text(file_path, type)
          case type
          when :pdf
            PDF::Reader.new(file_path).pages.map(&:text).join("\n")
          when :docx
            Docx::Document.open(file_path).text
          when :txt, :html, :csv, :rtf, :odt
            File.read(file_path, encoding: 'utf-8')
          else
            ""
          end
        rescue => e
          "Error: #{e.message}"
        end
      end
    end
  end
end