LLVM_DIR=$HOME/Repositories/llvm-project/

export PROFILE_DIR="$HOME/Brewery/w3phoenix/tools/w3phoenix-sdk"

export GTEST_COLOR=yes

export PATH="$HOME/.local/bin:$PATH"
export PATH="$LLVM_DIR/build/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
