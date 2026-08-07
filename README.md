# Dotfiles setup

```zsh
curl -fsSL https://raw.githubusercontent.com/kplieven/dotfiles/master/scripts/dependencies.sh | bash
curl -fsSL https://raw.githubusercontent.com/kplieven/dotfiles/master/scripts/config-init.sh | bash
```

Run `dependencies.sh` first if you want the machine prerequisites installed for you. It is intended for Ubuntu/Debian and can install shell, Rust, Neovim, Git, terminal, and desktop packages.

`config-init.sh` then:

1. Clones the bare repo into `~/.dotfiles` if it is missing.
2. Checks out the tracked files into your home directory.
3. Moves any conflicting files into `~/.dotfiles-backup/` and retries the checkout.
4. Disables untracked-file noise in the dotfiles repo.

## What gets loaded

`~/.zshrc` sources the files in `~/.zsh/` in this order:

1. `completion.zsh`
2. `env.zsh`
3. `antigen.zsh`
4. `plugins.zsh`
5. `prompt.zsh`
6. `aliases.zsh`

That means your shell setup, PATH changes, plugin loading, prompt, and aliases are split into small, focused files.
