source /usr/share/cachyos-fish-config/cachyos-config.fish

set -gx SSH_AUTH_SOCK "$HOME/.bitwarden-ssh-agent.sock"
alias dots='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
