config_files=(
    "completion.zsh"
    "env.zsh"
    "antigen.zsh"
    "plugins.zsh"
    "prompt.zsh"
    "aliases.zsh"
)

# zmodload zsh/zprof

# Only generate completions if zsh files are newer than the zcompdump
autoload -Uz compinit
zsh_files_newer=false

for file in ~/.zsh/*; do
    if [[ $file -nt ~/.zcompdump ]]; then
        zsh_files_newer=true
        break
    fi
done

if [[ -f ~/.zcompdump && $zsh_files_newer == false ]]; then
    compinit -C
else
    compinit
fi

for config in $config_files; do 
    # echo "Configuring $config"
    source $HOME/.zsh/$config
done

# zprof
