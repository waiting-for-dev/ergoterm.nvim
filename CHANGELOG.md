# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

- BREAKING: `select()` & `select_started()` now take table of options instead of ordered parameters.
- `select_started()` can take a `default` option to provide default terminal if none of the list is started.
- List and table options can be passed to `TermNew` & `TermUpdate` commands.
- Add new `:TermInspect` command to inspect terminal settings.

## 0.7.0 - 2025-10-13

- BREAKING: Rename `with_tag()` to `filter_by_tag()`.
- BREAKING: `term:update()` completely replaces table settings instead of merging them.
- DEPRECATED: Rename `:send()` allowed action names:
  - `silent` -> `start`
  - `visible` -> `open`
  - `interactive` -> `focus`
- `:send()` will ensure terminal is in the action state before sending input.
- Resize splits on `VimResized` event.
- Fix option names auto-completion in commands.
- `persist_size` option to remember the size of split terminals

## 0.6.0 - 2025-10-06

- Add `:prompt()` text decorator.
- Notify when trying to send to a terminal that hasn't been started yet.
- Available text decorators by name can be configured in `config.text_decorators`.
- `.select()` can take a single function instead of a table of callbacks.
- `.select()` to fast-forward if single terminal and single default callback
- Add `.select_started()` function to select only among started terminals.
- Add new `meta` table settings for custom user data.

## 0.5.0 - 2025-09-27

- Add `.with_defaults()` as a factory builder for terminals with custom defaults.
- Add `default_action` setting to configure what the picker does on selecting with `<Enter>`.
- Add `show_on_success` & `show_on_failure` settings.
- Fix closing terminal window when it is the last one.

## 0.4.0 - 2025-09-22

- BREAKING: `cleanup_on_failure` defaults to `false` now.
- BREAKING: `selectable` only controls picker visibility, while new `bang_target` controls a terminal being a target for bang commands.
- Add `tags` option to terminals and filtering by specific tag.
- Fix splits not being at the top level.

## [0.3.5] - 2025-09-18

- Fix opening picker from float terminal
- Fix opening float terminal from another float terminal

## [0.3.4] - 2025-09-14

- Fix fully refresh float window when focusing

## [0.3.3] - 2025-09-14

- Actually fix invalid win ID when opening a floating terminal

## [0.3.2] - 2025-09-14

- Fix invalid win ID when opening a floating terminal

## [0.3.1] - 2025-09-05

- Fix autocommands not being working because of not matching the pattern correctly.

## [0.3.0] - 2025-09-04

- BREAKING: `auto_scroll` is off by default now.
- BREAKING: `cleanup_on_success` & `cleanup_on_failure` replace `close_on_job_exit`.
- Add `watch_files` option to refresh buffer on stdout
- `cleanup_on_success` & `cleanup_on_failure` control not only closing the terminal window but also cleaning up the terminal instance.
- Fixed vim-ui-select picker not working as expected.
- Remove `WinEnter` event listener and do everything on `BufEnter` instead.
- Cleanup terminals on `BufWipeout`.
- Remove id from picker display and add status icons
- Fix previewing non-active sticky terminals
- Fix autocommands not working

## [0.2.0] - 2025-07-31

- Allow last focused non selectable terminal to be focused when universal selection is turned on.
- Add `size` option for split layouts, accepting both numeric and percentage values.
- Make floating terminals resize
- Add `sticky` option for terminals visible from the picker even if not started.
- BREAKING: Rename `term:delete()` to `term:cleanup()` and `terms.delete_all()` to `terms.cleanup_all()`.

## [0.1.2] - 2025-07-24

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
