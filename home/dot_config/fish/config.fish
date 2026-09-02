source /usr/share/cachyos-fish-config/cachyos-config.fish

set -gx SSH_AUTH_SOCK "$HOME/.bitwarden-ssh-agent.sock"
# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# pnpm
set -gx PNPM_HOME "/home/robin/.local/share/pnpm"
if not string match -q -- "$PNPM_HOME/bin" $PATH
    set -gx PATH "$PNPM_HOME/bin" $PATH
end
# pnpm end
