# this will autostart tmux if $fish_tmux_autostart is set to `true` using the `--on-variable` function option
function _fish_tmux_plugin_run_autostart --on-variable fish_tmux_autostart
    if test "$fish_tmux_autostart" = true && \
    test -z "$TMUX" && \
    test -z "$INSIDE_EMACS" && \
    test -z "$EMACS" && \
    test -z "$NVIM" && \
    test -z "$VSCODE_RESOLVING_ENVIRONMENT" && \
    test "$TERM_PROGRAM" != 'vscode'

        # tmux a       default   silence  if fails    new sesh    default    kill old fish (auto close when tmux closes
        tmux attach -t default 2>/dev/null || tmux new-session -s default && kill $fish_pid
    end
end

