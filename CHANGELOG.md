# Telegem Changelog


## v3.3.2-rc.1

### Fixed
- Webhook `set_webhook` now correctly passes URL as positional argument
- Removed unsafe thread usage in `Context#with_typing` (async-safe now)
- Added automatic retry with exponential backoff in API client
- Improved `telegem-ssl` to detect dnf/yum on Fedora/RHEL

### Changed
- No breaking changes. Safe upgrade from v3.3.1.


## v3.3.1
### Features 
- improved memeorystore to include diskbackup
- added 'telegem-init' cli 


## v3.1.1 

### New Features

-FileExtractor Plugin: New plugin for extracting content from various file types (PDF, JSON, HTML, TXT)
- Async File Download: Added download method to API client for downloading Telegram files
- Context File Helpers: Added download_file, download_photo, download_document methods to Context
- Extended File Support: Plugin supports PDF text extraction, JSON parsing, HTML/raw text processing
- Async/Sync Dual Mode: All file operations available in both sync (download) and async (download!) modes

## v3.1.0 

### features 
- BREAKING: Rewrote polling system to prevent duplicate messages
- Fixed thread deadlock in async polling loop
- Added scene_middleware.rb for scene-based conversations
- Improved MemoryStore with TTL and thread safety
- Enhanced keyboard markup builder with web_app support
-  Added message reaction and chat boost update types
- Fixed callback query handling for inline keyboards

## v3.0.0
### features 

- BREAKING: Complete async rewrite with async gem
- New HTTP client using HTTPX with proper async/await pattern
- Added scene system for multi-step conversations
- Middleware composer system for plugin architecture
- Type system with dynamic accessors for Telegram objects
- Session management with memory store
- Rate limiting middleware
- File upload support via multipart forms

## v2.0.0

- BREAKING: Ruby 3.0+ requirement
- Added webhook support with Rack middleware
- Inline query and callback query handlers
- Location, contact, and poll answer handlers
- Keyboard markup helpers (Telegem::Markup)
- Improved error handling with custom error classes
- Logging integration with configurable loggers

## v1.5.0

- Added command argument parsing (ctx.command_args)
- Message entity parsing (mentions, hashtags, bot commands)
- Chat member update handlers
- Pre-checkout and shipping query support
- File download helper methods
- Context helper methods for common API calls

## v1.0.0

- Stable API release
- Message handlers with text pattern matching
- Command handlers with regex support
- Basic context object with chat/message accessors
- Simple API client with error handling
- Polling and webhook modes
- Configuration options for timeout and limits

## v0.5.0

- Added callback query support
- Inline keyboard builder
- Message editing and deletion helpers
- Media sending methods (photo, document, audio, video)
- Chat action methods (typing, upload indicators)

## v0.3.0

- Middleware system with bot.use
- Session management foundation
- Basic rate limiting
- Command filtering by chat type
- Improved logging with debug levels

## v0.2.0

- Basic polling implementation
- Message type detection (text, photo, document)
- Command parsing with arguments
- Simple reply methods
- Error handling for API calls

## v0.1.0 (Initial Release)

- Basic Telegram Bot API wrapper
- Send/receive messages
- Simple command handling
- Minimal dependencies (just httparty)
- Support for basic message types

---
