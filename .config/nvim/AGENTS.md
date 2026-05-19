# LazyVim Configuration

## Project Overview

This is a personal [Neovim](https://neovim.io/) configuration based on [LazyVim](https://github.com/LazyVim/LazyVim), a popular Neovim configuration distribution. It uses [lazy.nvim](https://github.com/folke/lazy.nvim) as the plugin manager. The configuration is written in Lua and follows LazyVim's conventions and modular structure.

The repository is essentially a starter template with minimal overrides. Most settings rely on LazyVim defaults, and customizations can be added by editing the files under `lua/config/` and `lua/plugins/`.

## Technology Stack

- **Editor**: Neovim (>= 0.9 required by LazyVim)
- **Language**: Lua
- **Plugin Manager**: lazy.nvim
- **Configuration Framework**: LazyVim
- **Formatter**: StyLua
- **License**: Apache License 2.0

## Project Structure

```
.
├── init.lua                  -- Entry point; bootstraps lazy.nvim
├── lazy-lock.json            -- Plugin version lockfile
├── lazyvim.json              -- LazyVim metadata (version, extras, news)
├── stylua.toml               -- StyLua formatter configuration
├── .neoconf.json             -- neoconf / neodev settings for lua_ls
├── lua/
│   ├── config/
│   │   ├── lazy.lua          -- Plugin manager bootstrap & LazyVim setup
│   │   ├── options.lua       -- Neovim options (empty; uses LazyVim defaults)
│   │   ├── keymaps.lua       -- Custom keymaps (empty; uses LazyVim defaults)
│   │   └── autocmds.lua      -- Autocommands (empty; uses LazyVim defaults)
│   └── plugins/
│       └── example.lua       -- Example plugin specs (currently disabled)
```

### Key Files

| File | Purpose |
|------|---------|
| `init.lua` | Requires `config.lazy` to bootstrap the plugin manager. |
| `lua/config/lazy.lua` | Clones lazy.nvim if missing, then calls `require("lazy").setup()` to load LazyVim core plugins and custom plugins under `lua/plugins/`. |
| `lua/config/options.lua` | Override Neovim options. Loaded before lazy.nvim startup. |
| `lua/config/keymaps.lua` | Override or add keymaps. Loaded on the `VeryLazy` event. |
| `lua/config/autocmds.lua` | Override or add autocommands. Loaded on the `VeryLazy` event. |
| `lua/plugins/*.lua` | Plugin specification files. Every file in this directory is automatically imported by lazy.nvim. Return a table of plugin specs. |
| `lazy-lock.json` | Auto-generated lockfile tracking exact plugin commits. Do not edit manually. |
| `lazyvim.json` | LazyVim's own config file tracking installed extras, install version, and news state. |
| `.neoconf.json` | Enables `neodev` library and `lua_ls` plugin support for better Lua development inside Neovim. |
| `stylua.toml` | Formatter config: 2-space indentation, 120 column width. |

## Runtime Architecture

1. **Neovim startup** reads `init.lua`.
2. `init.lua` requires `lua/config/lazy.lua`.
3. `lazy.lua` checks for `lazy.nvim` in Neovim's data directory and clones it if absent.
4. `lazy.nvim` is prepended to the runtime path.
5. `require("lazy").setup()` is called with two spec sources:
   - `{ "LazyVim/LazyVim", import = "lazyvim.plugins" }` — loads the entire LazyVim distribution.
   - `{ import = "plugins" }` — loads all Lua files under `lua/plugins/` as plugin specs.
6. LazyVim loads `lua/config/options.lua` before plugin initialization, then loads `keymaps.lua` and `autocmds.lua` on the `VeryLazy` event.

## Adding or Modifying Plugins

Create new `.lua` files under `lua/plugins/`. Each file should return a table of plugin specs. Examples of what you can do:

- Add a new plugin: `{ "author/plugin-name", opts = { ... } }`
- Override a LazyVim plugin's options: return a spec with the same plugin name and `opts`.
- Disable a plugin: `{ "folke/trouble.nvim", enabled = false }`
- Import LazyVim extras: `{ import = "lazyvim.plugins.extras.lang.typescript" }`

The existing `lua/plugins/example.lua` contains commented examples but is currently disabled at the top with:

```lua
if true then return {} end
```

## Code Style Guidelines

- **Formatter**: StyLua (`stylua.toml`)
- **Indentation**: 2 spaces
- **Column width**: 120 characters
- Use `--` for single-line comments and `--[[ ... ]]` for block comments.
- Follow Lua conventions and LazyVim's existing plugin spec patterns.

## Commands

There is no external build, test, or deployment process for this project. The configuration is "live" — changes take effect on the next Neovim startup or when plugins are reloaded via lazy.nvim.

| Action | How |
|--------|-----|
| Format Lua files | `stylua .` (requires StyLua installed) |
| Update plugins | Inside Neovim, run `:Lazy update` |
| Sync plugins | Inside Neovim, run `:Lazy sync` |
| Check plugin status | Inside Neovim, run `:Lazy` |
| Health check | Inside Neovim, run `:checkhealth` |

## Testing

This project does not contain automated tests. Validation is done by opening Neovim and verifying that:

- No errors appear on startup.
- Expected plugins are loaded (`:Lazy`).
- Keymaps and options behave as intended.

## Security Considerations

- Plugins are cloned from GitHub repositories. The `lazy-lock.json` file pins exact commits, which helps protect against upstream supply-chain changes. Review lockfile changes before committing them.
- `version = false` is set in `lua/config/lazy.lua`, meaning plugins track the latest git commit by default for plugins that do not specify a version. Be cautious when updating.
- No secrets, tokens, or sensitive data should be stored in this repository.

## Notes for AI Agents

- This is a **Neovim configuration**, not a standalone application. There is no `package.json`, `pyproject.toml`, `Cargo.toml`, or similar manifest.
- Most files under `lua/config/` are currently empty placeholders. Add customizations there rather than replacing the entire LazyVim default set.
- When adding plugins, prefer creating a new file under `lua/plugins/` rather than editing `example.lua`.
- LazyVim's default options, keymaps, and autocommands can be found at [lazyvim/config](https://github.com/LazyVim/LazyVim/tree/main/lua/lazyvim/config). Use those as reference when overriding.
