config_files=(
    "completion.zsh"
    "env.zsh"
    "antigen.zsh"
    "plugins.zsh"
    "prompt.zsh"
    "aliases.zsh"
)

# zmodload zsh/zprof

for config in $config_files; do 
    # echo "Configuring $config"
    source $HOME/.zsh/$config
done

# zprof
