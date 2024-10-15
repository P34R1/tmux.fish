# wrapper function for tmux
function _fish_tmux_plugin_run
    set tmux_cmd tmux

    $tmux_cmd new-session
end

# this will autostart tmux if $fish_tmux_autostart is set to `true` using the `--on-variable` function option
function _fish_tmux_plugin_run_autostart --on-variable fish_tmux_autostart
    if test "$fish_tmux_autostart" = true && \
    test -z "$TMUX" && \
    test -z "$INSIDE_EMACS" && \
    test -z "$EMACS" && \
    test -z "$NVIM" && \
    test -z "$VSCODE_RESOLVING_ENVIRONMENT" && \
    test "$TERM_PROGRAM" != 'vscode'
        _fish_tmux_plugin_run
    end
end
