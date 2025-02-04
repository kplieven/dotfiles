LLVM_DIR=$HOME/Repositories/llvm-project/

export GTEST_COLOR=yes

export PATH="$HOME/.local/bin:$PATH"
export PATH="$LLVM_DIR/build/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

FNM_PATH="/home/karlie/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/home/karlie/.local/share/fnm:$PATH"
  eval "`fnm env`"
fi

export CDPATH=.:$HOME/Repositories/Barco

source $HOME/.cargo/env

if [ -z "$RUNNING_IN_DOCKER" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# source "/etc/profile.d/rvm.sh"
