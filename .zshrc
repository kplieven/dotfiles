config_files=(
    "aliases.zsh"
    "completion.zsh"
    "env.zsh"
    # "antigen.zsh"
    # "plugins.zsh"
    "prompt.zsh"
)

for config in $config_files; do 
    echo "Configuring $config"
    source $HOME/.zsh/$config
done
