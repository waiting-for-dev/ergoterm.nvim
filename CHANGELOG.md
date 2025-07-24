# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

- Allow updating the `close_on_job_exit` setting from the `:TermUpdate` command.
- Allow creating a terminal with all other boolean settings.
- Recompute directory on `term:start()`.

## [0.1.1] - 2025-07-23

- Added support for `picker.select_actions` & `picker.extra_select_actions` settings.
- Fix `close_job_on_exit` not being respected.
- Fix `git_dir` value for `dir` not expanding to the actual git directory when starting a terminal.

## [0.1.0] - 2025-07-19

- BREAKING: Config is now nested under `config.terminal_defaults` & `config.picker` objects
- Fix Telescope actions descriptions

## [0.0.3] - 2025-07-19

- BREAKING: `Terminal:send` takes options as a table instead of ordered parameters.
- `Terminal:send` accepts `decorator` option as a string to look up by name.

## [0.0.2] - 2025-07-19

- `Terminal:send` to support selection types in the `input` parameter: `single_line`, `visual_lines` or `visual_selection`.

## [0.0.1] - 2025-07-18

### Added
- Initial release
