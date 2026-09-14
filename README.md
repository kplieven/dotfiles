# Dotfiles setup

```zsh
curl -fsSL https://raw.githubusercontent.com/kplieven/dotfiles/master/scripts/dependencies.sh | bash
curl -fsSL https://raw.githubusercontent.com/kplieven/dotfiles/master/scripts/config-init.sh | bash
```

Both scripts open an interactive menu — including when piped through `bash`, so nothing is installed without being selected. Pass flags (`--shell --nvim`, or `--all`) to skip the menu.

Run `dependencies.sh` first if you want the machine prerequisites installed for you. It is intended for Ubuntu/Debian and can install shell, Rust, Neovim, Git, terminal, and desktop packages. Once the dotfiles are checked out it is also reachable as `config dependencies`, with the same menu and flags.

`config-init.sh` then:

1. Clones the bare repo into `~/.dotfiles` if it is missing.
2. Checks out **only the selected packages** into your home directory, via git sparse-checkout.
3. Moves any conflicting files into `~/.dotfiles-backup/` and retries the checkout.
4. Disables untracked-file noise in the dotfiles repo.

The menu comes pre-selected: on a first run from the dependencies detected on the machine (`nvim` installed, so the Neovim package is ticked), and afterwards from whatever is already checked out.

## Packages

| Package | Contents |
| --- | --- |
| `shell` | `.zshrc`, `.zsh/`, starship |
| `nvim` | `.config/nvim/` |
| `git` | `.gitconfig`, `.gitconfig-barco`, lazygit |
| `terminal` | kitty |
| `desktop-x11` | i3, polybar, dunst, rofi, picom, betterlockscreen, wallpapers |
| `desktop-wayland` | sway, waybar, kanshi |
| `copilot` | `.copilot/` |
| `agents` | `.agents/`, `.github/` |

`README.md` and `scripts/` are always checked out. GTK settings follow whichever desktop package is selected.

Change the selection at any time:

```zsh
config packages                 # menu, pre-ticked with what is checked out
config packages list            # what is selected, and how many files each has
config packages add nvim        # check a package out
config packages remove nvim     # remove it from $HOME
```

Removing a package deletes its files from `$HOME` but keeps them in the repo, where they go on receiving updates — so re-adding it later brings back the current version. A package with uncommitted changes is refused rather than left half-removed.

`config pull` and `config push` need no special handling: pulls update unselected files inside the repo without writing them to `$HOME`, and commits only ever see the packages you have checked out.

## What gets loaded

`~/.zshrc` sources the files in `~/.zsh/` in this order:

1. `completion.zsh`
2. `env.zsh`
3. `antigen.zsh`
4. `plugins.zsh`
5. `prompt.zsh`
6. `aliases.zsh`

That means your shell setup, PATH changes, plugin loading, prompt, and aliases are split into small, focused files.
