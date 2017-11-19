# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog], and while pre-1.0 development is in
progress this project adheres to a form of Semantic Versioning (see README.md).

[Keep a Changelog]: http://keepachangelog.com/en/1.0.0/

## [Unreleased]

## [0.10.0] - 2017-11-19
### Added
- Changelog for all notable modifications going forward.

### Changed
- Created a new "filter" stage, which replaces "preprocessor" as the first
  stage of Peribot message processing. Generally, filters should drop messages
  without modifying them, while preprocessors might modify a message or cause
  side effects.

### Removed
- The `Bot#register` convenience method, which was deprecated in 0.9.0. To
  register a service, use `bot.service.register MyService` instead of
  `bot.register MyService`.
- The `Bot#services` convenience method, which was deprecated in 0.9.0. To list
  the services registered for a bot instance, use `bot.service.list` instead of
  `bot.services`.
- The `ProcessorRegistry#tasks` alias, which was deprecated in 0.9.0. To list
  the processors registered for a given stage (e.g. the preprocessor), use
  `bot.preprocessor.list` instead of `bot.preprocessor.tasks`.

[Unreleased]: https://github.com/ahamlinman/peribot/compare/0.10.0...HEAD
[0.10.0]: https://github.com/ahamlinman/peribot/compare/0.9.1...0.10.0
