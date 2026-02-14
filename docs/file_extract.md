

# Telegem::Plugins::FileExtract

**Version:** 3.2.2  
**Status:** Production Ready  
**Dependencies:** `pdf-reader` 

---

## Overview

FileExtractor provides seamless document processing for Telegram bots. It automatically detects file types, extracts structured content, and handles all edge cases—eliminating boilerplate code for developers.

Unlike traditional approaches that require manual MIME type checking and format-specific handlers, FileExtractor implements a unified interface that works across all supported formats.

---

## Installation

Add to your Gemfile:

```ruby
gem 'telegem'
```

---

Quick Start

```ruby
# Initialize with any Telegram file_id
extractor = Telegem::Plugins::FileExtract.new(
  bot,
  ctx.message.document.file_id
)

# Extract content - auto-detects file type
result = extractor.extract

if result[:success]
  # Unified response structure across all file types
  puts "Type: #{result[:type]}"
  puts "Content: #{result[:content]}"
  puts "Metadata: #{result[:metadata]}"
else
  # Graceful error handling
  puts "Error: #{result[:error]}"
end
```

---

Supported Formats

| format | Mime type | extension | features |
 |:--------:| :--------:| :--------: |:--------:|
| pdf | application/pdf | .pdf | text extraction and page count |
| json| application/json | .json | ful parsibg nested structure |
| html | text/html | .html | tag stripping |
| plain text| text/plain | .txt | full content |
 

Note: All formats except PDF work without additional dependencies.

---

API Reference

Constructor

```ruby
def initialize(bot, file_id, **options)
```

| Parameter |  Type Required | Default Description |
 |:--------: | :--------:| :--------:| :--------:|
| bot | Telegem::Bot ✓ | – Active bot instance
| file_id | String ✓|  – Telegram file identifier
| auto_delete |  Boolean  |true Remove temp files after processing|
| max_size | Integer | 50_000_000 Maximum file size in bytes (50MB) |
| timeout | Integer  | 30 Processing timeout in seconds |


Instance Methods

extract → Hash

Processes the file and returns a standardized response hash.

Success Response:

```ruby
{
  success: true,
  type: :pdf,                 # Symbol identifying file format
  content: "extracted text",  # Parsed content (String, Hash, or Array)
  metadata: {
    size: 45210,             # File size in bytes
    # Format-specific fields (see below)
  },
  error: nil
}
```

Error Response:

```ruby
{
  success: false,
  type: :unknown,
  content: nil,
  metadata: {},
  error: "Descriptive error message"
}
```

---

Format-Specific Behavior

PDF Documents

Requirements: gem 'pdf-reader'

```ruby
result = extractor.extract

if result[:success]
  puts "Pages: #{result[:metadata][:pages]}"
  puts "Content: #{result[:content][0..500]}..."
end
```

Metadata:

```ruby
metadata: {
  pages: 12,        # Total page count
  size: 1048576     # File size in bytes
}
```

Error Cases:

- Malformed PDF format – Corrupted or invalid PDF structure
-  Encrypted PDF (password protected) – Document requires password
- PDF contains no extractable text – Scanned/image-only document

---

JSON Documents

```ruby
result = extractor.extract

if result[:success]
  # Content is already parsed Ruby objects
  data = result[:content]
  puts data['user']['name']  # Direct hash access
end
```

Metadata:

```ruby
metadata: {
  size: 1250,
  structure: "hash",    # "hash", "array", or "scalar"
  keys: 5              # Top-level keys (hash only)
}
```

Error Cases:

- Invalid JSON: unexpected token – Syntax error with position
- JSON file is empty – Zero-byte file
- File encoding not supported – Non-UTF8 encoding

---

HTML Documents

```ruby
result = extractor.extract

if result[:success]
  # HTML tags stripped, whitespace normalized
  text = result[:content]
  
  # Original HTML available when keep_original: true
  original = result[:metadata][:original] if @keep_original
end
```

Metadata:

```ruby
metadata: {
  size: 3072,
  original: "<html>...</html>"  # Only if keep_original: true
}
```

Error Cases:

- HTML file is empty – Zero-byte file
- HTML contains no extractable text – Only tags, comments, or scripts

---

Text-Based Formats (TXT, CSV, Markdown)

```ruby
result = extractor.extract

if result[:success]
  lines = result[:metadata][:lines]
  encoding = result[:metadata][:encoding]
end
```

Metadata:

```ruby
metadata: {
  size: 2048,
  lines: 42,           # Line count
  encoding: "UTF-8"    # Detected encoding
}
```

Error Cases:
- Text file is empty – Zero-byte file
- File encoding not supported – Binary or invalid UTF-8

---

Error Handling

FileExtractor never raises exceptions during normal operation. All errors are captured and returned in the standardized hash format.



Client-Side Error Handling

```ruby
result = extractor.extract

unless result[:success]
  case result[:error]
  when /encrypted/i
    ctx.reply("🔒 Please send an unencrypted PDF")
  when /malformed/i
    ctx.reply("📄 File appears corrupted, please resend")
  when /size exceeds/i
    ctx.reply("📦 File too large (max 50MB)")
  else
    ctx.reply("❌ #{result[:error]}")
  end
end
```

---


Benchmarks: (50KB file, Ruby 3.2)

-  PDF: ~150ms
-  JSON: ~20ms
- HTML: ~15ms
- Text: ~5ms

---

Security Considerations

File Size Limits

Default max_size: 50_000_000 prevents denial-of-service attacks via large file uploads.

Temporary File Management

All files are written to Dir.tmpdir with:

- Random filename generation (SecureRandom.hex)
-  Automatic deletion (auto_delete: true)
-  Explicit cleanup in ensure blocks

Memory Protection

- Large files are never fully read into memory unless required
- Streaming parsers used where available
-  Configurable timeouts prevent hanging operations

---

Common Patterns

Reply-to-Message Processing

```ruby
bot.command('extract') do |ctx|
  replied = ctx.message.reply_to_message
  
  if replied&.document
    result = FileExtractor.new(bot, replied.document.file_id).extract
    
    if result[:success]
      ctx.reply("📄 Extracted from #{result[:type]}:\n\n#{result[:content][0..300]}")
    else
      ctx.reply("❌ #{result[:error]}")
    end
  end
end
```

Batch Processing

```ruby
files = updates.map do |update|
  next unless update.message&.document
  
  Thread.new do
    FileExtractor.new(bot, update.message.document.file_id).extract
  end
end.map(&:value)
```

Caching Extracted Content

```ruby
class CachedExtractor < Telegem::Plugins::FileExtractor
  def extract
    cache_key = "extract:#{@file_id}"
    
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      super
    end
  end
end
```

---

Troubleshooting

PDF::Reader Not Found

```
LoadError: cannot load such file -- pdf/reader
```

Solution: gem install pdf-reader or add to Gemfile

File ID Expired

```
Error: File not found
```

Solution: File IDs expire after 24 hours. Request fresh file from user.

Memory Usage Spikes

Solution: Reduce max_size or process files sequentially rather than in parallel.

Unsupported File Types

Solution: Check file extension or MIME type before extraction:

```ruby
if ctx.message.document.mime_type.start_with?('image/')
  # Handle images separately
else
  result = FileExtractor.new(bot, file_id).extract
end
```
