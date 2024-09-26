LLVM_DIR=$HOME/Repositories/llvm-project/

export GTEST_COLOR=yes

export PATH="$HOME/.local/bin:$PATH"
export PATH="$LLVM_DIR/build/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export CDPATH=.:$HOME/Repositories/Barco

source $HOME/.cargo/env

if [ -z "$RUNNING_IN_DOCKER" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# source "/etc/profile.d/rvm.sh"
