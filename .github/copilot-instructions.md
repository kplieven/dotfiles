# Copilot Instructions for dotfiles

## Repository Architecture

This is a **bare git repository** at `~/.dotfiles` that manages dotfiles directly in `$HOME` using the git bare repo pattern. The working tree is `$HOME`, not the repo directory itself.

### The `config` alias

All git operations must use the `config` alias (defined in `.zsh/aliases.zsh`):

```sh
alias config='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

Use `config` instead of `git` for all operations:

```sh
config status
config add .config/nvim/lua/plugins/foo.lua
config commit -m "nvim: add foo plugin"
```

Untracked files are hidden by design (`status.showUntrackedFiles = no`). Only explicitly added files are tracked.

### Tracked config areas

| Directory | What it configures |
|---|---|
| `.config/nvim/` | Neovim (Lua config, `vim.pack` plugin manager) |
| `.config/kitty/` | Kitty terminal |
| `.config/i3/`, `.config/sway/` | Window managers (X11 / Wayland) |
| `.config/polybar/`, `.config/waybar/` | Status bars |
| `.config/lazygit/` | Lazygit |
| `.config/starship.toml` | Starship prompt |
| `.config/dunst/` | Notification daemon |
| `.zsh/`, `.zshrc` | Zsh shell (antigen plugin manager, oh-my-zsh) |
| `.gitconfig` | Global git config |
| `scripts/` | Setup and utility scripts |

## Conventions

### Commit messages

Use the format `<scope>: <description>` where scope matches the config area:

```
nvim: add treesitter
zsh (env): add opencode to path
polybar: change alert colours
i3: make colours uniform with dunst and polybar
```

Parenthetical subscopes like `zsh (env)` are used when a change targets a specific file within a config area.

### Neovim plugin management

Plugins are managed with `vim.pack` (native Neovim package manager, not lazy.nvim). Key patterns:

- Each plugin gets its own file in `.config/nvim/lua/plugins/` (e.g., `mini-files.lua`)
- `.config/nvim/lua/plugins/init.lua` registers build hooks via `PackChanged` autocmd and loads all plugin configs
- Add new plugins: create a config file, add `require("plugins.<name>")` in `init.lua`
- Build hooks for post-install/update actions go in the `PackChanged` autocmd in `init.lua`
- Run `:PackUpdate` to update all plugins

### Zsh configuration

`.zshrc` sources files from `.zsh/` in a specific order defined by `config_files`:

1. `completion.zsh` — completion setup
2. `env.zsh` — PATH, environment variables
3. `antigen.zsh` — antigen plugin manager bootstrap
4. `plugins.zsh` — zsh plugin declarations
5. `prompt.zsh` — starship prompt init
6. `aliases.zsh` — shell aliases

### Indentation

4 spaces (configured in nvim options and used throughout Lua configs).
