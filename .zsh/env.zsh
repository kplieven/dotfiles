export GTEST_COLOR=yes

export PATH="$HOME/.local/bin:$PATH"
export PATH="$LLVM_DIR/build/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH=$HOME/.opencode/bin:$PATH

FNM_PATH="/home/karlie/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/home/karlie/.local/share/fnm:$PATH"
  eval "`fnm env`"
fi

export CDPATH=.:$HOME/repos/barco-labs/:$HOME/repos/personal/

source $HOME/.cargo/env

PYENV_PATH="$HOME/.pyenv"
if [ -d "$PYENV_PATH" ]; then
    command -v pyenv >/dev/null || export PATH="$PYENV_PATH/bin:$PATH"
    eval "$(pyenv init -)"
fi

# VSCode shell integration
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

# Machine-local secrets (access keys, tokens) live in an untracked file.
[[ -f "$HOME/.zsh/secrets.zsh" ]] && source "$HOME/.zsh/secrets.zsh"
