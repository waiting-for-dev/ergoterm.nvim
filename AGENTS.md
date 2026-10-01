# ergoterm

ergoterm.nvim is a flexible, terminal-first Neovim plugin for managing terminals. Instead of offering tool-specific integrations (AI agents, test runners, task runners, etc.), it provides a single terminal abstraction that adapts to any CLI tool, letting users configure layout, size, autohide, and other behaviors per terminal or globally.

## Architecture

The codebase is a thin public façade over four layers: public API, instance methods, collection methods and vim events. Behavior lives in per-action files; the four layers above them stay thin and only delegate.

### Public API — `lua/ergoterm.lua`

The only module users are meant to require. It must contain no logic beyond wiring:

- `setup(user_prefs)`.
- Re-exports of `collection` methods.
- `M:new(args)` to create instances.
- `M.with_defaults(custom_defaults)` to create a terminal factories.
- `M.text_decorators` for users who want to reference decorators directly.

Rules:
- Never add behavior here. New public functions are re-exports of a `collection` or `instance` function, or a small factory like `with_defaults`.
- `lua/ergoterm/terminal.lua` is a frozen deprecated shim. Do not add anything to it.

### Instance methods — `lua/ergoterm/instance.lua`

Defines the `Terminal` class, its `@class`/`@field` annotations, `Terminal:new()`, and every instance method. Method files own the doc comments (`---@param`, `---@return`, prose); per-action files must not duplicate them.

Each public method is a one-line delegation: e.g, `return start(self)`.

- Simple predicates and pure logic stay inline: e.g., `is_active`.
- Methods that only forward to an event module (`on_buf_enter`, `on_win_leave`) forward to `events/`, not to `instance/`.

### Per-action instance files — `lua/ergoterm/instance/*.lua`

One file per action, named after the method it powers (e.g., `open.lua`). Each exports plain functions taking the terminal as the first argument: `function M.open(term, layout)`.

Nesting is allowed when a file grows: `instance/send/text_selector.lua` and `instance/send/text_decorators.lua` are helpers of `send`.

`is_started` and siblings are co-located with their action file and re-exported by `instance.lua`.

### Collection methods — `lua/ergoterm/collection.lua`

Owns the session state `_state` (e.g., `terminals`) and the private `_compute_id` / `_add_terminal_to_state` that `instance.lua` calls. Query methods (e.g., `find`) are simple one-liners and stay inline.

Complex collection behavior goes to `lua/ergoterm/collection/select.lua` (`select`, `select_started`), which also handles the single-terminal short-circuit. It is callable (`setmetatable` `__call`) so it can be invoked as `select(defaults)`.

### Commands — `lua/ergoterm/commands.lua` + `lua/ergoterm/commandline.lua`

`M.setup(conf)` registers the user commands (e.g., `TermNew`) and does nothing else. Each command handler delegates to `M.<action>`.

Command actions contain no domain logic. They only:
1. `commandline.parse(args)` and `vim.validate` the parsed values.
2. Resolve the target terminal via `_execute_if_single_terminal` / `_execute_on_terminal` / `_execute_on_annotation_target` (bang → last focused, `target=` → by name, otherwise picker).
3. Call the public API or an instance method (`require("ergoterm").select(...)`, `t:focus()`, `t:send(...)`) inside a callback.
4. Notify the user (`utils.notify`) when there is nothing to act on.

Never manipulate windows, buffers, jobs, or collection state from a command. `commandline.lua` is parse and completion only — no behavior. `text_decorators` and config are reached through their owning modules.

### Events — `lua/ergoterm/events/*.lua`

One module per Neovim event (e.g., `on_buf_enter`). Each exports a plain function receiving the terminal, and is a `setmetatable` `__call` module so it can be invoked either way.

### Support modules

- `config.lua` — single source of truth for defaults, `get(key)` dotted access, `set(user_prefs)`, `build_picker`, decorator and picker callback resolution, plus all shared `@class`/`@alias` types.
- `utils.lua` — `notify`, `git_dir`, dir helpers. All user-facing messages go through `utils.notify`.
- `mode.lua` — terminal mode constants and helpers.
- `size_utils.lua` — percentage/absolute size math.
- `pickers/p_telescope.lua`, `p_fzf_lua.lua`, `p_vim_ui_select.lua` — implement the `Picker` interface; always lazily `require`d, never at load time, so missing optional deps never break `setup()`.
- `health.lua` — `:checkhealth` support.

## Conventions

- No require cycles: `ergoterm.lua` requires everything at the top; everything else requires `require("ergoterm")` lazily inside function bodies (see `commands.lua`, `autocommands.lua`).
- No load-time side effects in modules.
- Every `require` gets a `---@module "..."` annotation; type annotations are LuaLS-style (`---@class`, `---@field`, `---@param`, `---@return`, `---@private`).
- Public types are declared once in `config.lua` and reused, not redeclared per file.
- Anything starting with `_` is a private method and gets the `--@private` annotation. It stays internal to the module and is not re-exported.

## Documentation

Five surfaces, each with a different audience. There is no doc generator: `doc/ergoterm.txt` is hand-maintained.

- `README.md` — the front door. Philosophy, setup, use-case links, then the configuration reference. Tables are alphabetical; subkeys are `↳ subkey` rows directly under their parent. This table is the canonical list of terminal options.
- `docs/api-reference.md` — markdown API reference, the writable counterpart of section 6 in the help file. One `#### method(...)` block per method: prose, a `**Parameters:**` table, `**Returns:**`, then `**Example:**`. It deliberately does not repeat the option list: `ergoterm:new(args)` and `term:update(settings, opts)` link to `README.md#terminal-defaults`. Only add rows for creation-time parameters (`cmd`, `dir`, `env`, `name`, `meta`, `tags`) or when a default/behavior described there changes.
- `doc/ergoterm.txt` — `:help ergoterm`, hand-maintained. Fixed width 78 columns, 8-space indent (`vim:tw=78:ts=8`), one help tag per public entry, tags right-aligned on the same line as the name. Sections: 1 Introduction, 2 Setup, 3 Use Cases, 4 Configuration, 5 Commands, 6 API Reference, 7 About. Every section and sub-section needs a line in the CONTENTS block at the top.
- `docs/*.md` guides — task-oriented narratives (e.g., `on-demand-usage`). Both README and help section 3 summarize a use case and link to the guide by URL, so update the guide and its summary together.
- `CHANGELOG.md` — one line per user-facing change under `## [Unreleased]`, prefixed `Add`, `Fix:` or `BREAKING:`.

Rules:

- Copy signatures and defaults from the source: `---@param` / `---@return` for methods, the `terminal_defaults` table in `config.lua` for defaults, `ParsedArgs` for accepted command options. Verify against `lua/` before writing prose, and fix the code rather than documenting a behavior it does not have.
- Keep the same shape in `docs/api-reference.md` and help section 6 — a method documented in one belongs in the other.
- Only document what is reachable: an option missing from `_term_new_options` is not a `:TermNew` option, and an option missing from `ALLOWED_SETTINGS` is not updatable. Both are documented as such (`doc/ergoterm.txt` `:TermUpdate` exception list).
- Document current behavior, never planned behavior.

## Adding a new terminal option

An option touches six places. Walk them in this order; each one is skipped only if it does not apply.

1. **Type and default — `lua/ergoterm/config.lua`.** Add `---@field <option> <type>?` to `TerminalDefaultsFromConfig`. Add the default value to the `terminal_defaults` table in `config`.
2. **Instance field — `lua/ergoterm/instance.lua`.** Add `---@field <option> <type>` to `---@class Terminal` and resolve the value in `Terminal:new()`: `vim.F.if_nil(term.<option>, config.get("terminal_defaults.<option>"))` for booleans and numbers (so an explicit `false` survives), `term.<option> or config.get(...)` for strings, and `vim.tbl_deep_extend("keep", term.<option> or {}, config.get(...))` for tables.
3. **Parsing — `lua/ergoterm/commandline.lua`.**
   - Add `---@field <option> <type>?` to `---@class ParsedArgs`.
   - Boolean option: add `<option> = true` to the local `boolean_options` table inside `M.parse` so `_toboolean` is applied.
   - Nested option (`foo.bar`): add `foo` to `M.nested_table_settings` with its allowed subkeys, and `["foo.bar"] = true` to `M.nested_boolean_settings` when the subkey is a boolean. Both are needed — the first parses `foo.bar=1` into a table, the second coerces the value.
   - List option (`a,b,c`): add `<option> = true` to `M.list_settings`.
   - Free-form map (`env.FOO`, `meta.bar`): add the trailing-dot key `"<option>."` to `M._all_options`; parsing already keeps the whole dotted key.
   - Completion: add `<option>` to `M._all_options` (`M._boolean_options` for booleans, `function() return {} end` for anything free-form, or a filtering function for closed value sets like `layout`), then reference it from every command that accepts it, in `M._term_new_options` and `M._term_update_options`. Missing an entry here means the option works but never shows up in completion.
4. **Command wiring — `lua/ergoterm/commands.lua`.** Add `vim.validate("<option>", parsed.<option>, "<type>", true)` to `M.new` and/or `M.update`. `M.new` also builds the `Terminal:new({...})` table key by key, so add `<option> = parsed.<option>` there. `M.update` forwards the whole parsed table to `t:update()`, so validation is all it needs (it strips `target` before doing so).
5. **Update allowlist — `lua/ergoterm/instance/update.lua`.** Add the option to `ALLOWED_SETTINGS`, unless it is immutable after creation (`cmd`, `dir`, `scrollback`, callbacks like `on_*`). Without this entry `term:update()` bails out with `Cannot change <option> after terminal creation`. If the option feeds derived `_state` (mode, layout, size, job handlers), recompute it in `M._recompute_state`, which runs after every update.
6. **Consumers.** Read `term.<option>` from the `instance/*.lua` or `events/*.lua` action that needs it. No wiring beyond that.

Docs and tests:

- `README.md` options table (alphabetical). If the option is a new terminal property, add it to the "Terminal Defaults" table; if it's nested (e.g., `annotations.foo`), document under the appropriate subsection.
- `docs/api-reference.md` - if the option affects instance creation/config or instance methods, update parameter tables and defaults as needed.
- `doc/ergoterm.txt` (`:help ergoterm`) — hand-maintained, not generated. Add an `*ergoterm-<option>*` entry under OPTIONS in `4.1 TERMINAL DEFAULTS`, keeping entries alphabetical, the tag right-aligned on the same line as the name, and text within 78 columns. Also add it to the CONTENTS block if you add a new section, and update the `:TermNew` / `:TermUpdate` notes when the option's command support changes (immutable options go in the `:TermUpdate` exception list).
- `CHANGELOG.md` under `[Unreleased]` with a short description.
- `spec/ergoterm/config_spec.lua` for the default, `spec/ergoterm/instance_spec.lua` for the resolved value, `spec/ergoterm/commandline_spec.lua` for parsing and completion, `spec/ergoterm/commands_spec.lua` for validation and wiring, `spec/ergoterm/instance/update_spec.lua` for the allowlist and recomputation.

## Tests

`spec/` mirrors `lua/` one to one, with `spec/support/test_helpers.lua` for shared mocks. Run with `busted`. Specs call `collection.cleanup_all({ force = true })` and `collection.reset_ids()` in `after_each`. Lint is `lua-language-server --configpath=.luarc.json --checklevel=Information --check lua/ spec/`.
