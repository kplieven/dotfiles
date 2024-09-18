LLVM_DIR=$HOME/Repositories/llvm-project/

export PROFILE_DIR="$HOME/Brewery/w3phoenix/tools/w3phoenix-sdk"

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

# Start the ssh-agent
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent > "$HOME/.ssh/ssh-agent.env"
fi

# Load the ssh-agent environment variables
if [ -f "$HOME/.ssh/ssh-agent.env" ]; then
    . "$HOME/.ssh/ssh-agent.env" > /dev/null
fi

ssh-add -k -q "$HOME/.ssh/id_ed25519_gh"

# source "/etc/profile.d/rvm.sh"
