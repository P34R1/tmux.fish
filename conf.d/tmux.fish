# global variables
set -q fish_tmux_autostart || set -g fish_tmux_autostart false
set -q fish_tmux_autostarted || set -gx fish_tmux_autostarted false
# set the configuration path
if test -e "$HOME/.tmux.conf"
    set -q fish_tmux_config || set -gx fish_tmux_config "$HOME/.tmux.conf"
else if test -e (set -q XDG_CONFIG_HOME || echo "$HOME/.config")/tmux/tmux.conf
    set -q fish_tmux_config || set -gx fish_tmux_config (set -q XDG_CONFIG_HOME || echo "$HOME/.config")/tmux/tmux.conf
else
    set -q fish_tmux_config || set -gx fish_tmux_config "$HOME/.tmux.conf"
end

# aliases
alias tksv="tmux kill-server"
alias tl="tmux list-sessions"
alias tmuxconf="$EDITOR $fish_tmux_config"
alias ta="tmux attach -t"
alias tad="tmux attach -d -t"
alias ts="tmux new-session -s"
alias tkss="tmux kill-session -t"

# wrapper function for tmux
function _fish_tmux_plugin_run
    if not type -q tmux
        echo "fish tmux plugin: tmux not found. Please install tmux before using this plugin." >&2
        exit 1
    end

    set -q fish_tmux_autoquit || set fish_tmux_autoquit $fish_tmux_autostart
    set -q fish_tmux_autoconnect || set fish_tmux_autoconnect true
    set -q fish_tmux_autoname_session || set fish_tmux_autoname_session false
    set -q fish_tmux_detached || set fish_tmux_detached false
    set -q fish_tmux_fixterm || set fish_tmux_fixterm true
    set -q fish_tmux_iterm2 || set fish_tmux_iterm2 false
    set -q fish_tmux_unicode || set fish_tmux_unicode false

    if test -e /usr/share/terminfo/t/tmux
        set -q fish_tmux_fixterm_without_256color || set fish_tmux_fixterm_without_256color "tmux"
    else
        set -q fish_tmux_fixterm_without_256color || set fish_tmux_fixterm_without_256color "screen"
    end

    if test -e /usr/share/terminfo/t/tmux-256color
        set -q fish_tmux_fixterm_with_256color || set fish_tmux_fixterm_with_256color "tmux-256color"
    else
        set -q fish_tmux_fixterm_with_256color || set fish_tmux_fixterm_with_256color "screen-256color"
    end

    # determine if the terminal supports 256 color
    if test (tput colors) = "256"
        set -gx fish_tmux_term $fish_tmux_fixterm_with_256color
    else
        set -gx fish_tmux_term $fish_tmux_fixterm_without_256color
    end

    # set the correct local config file to use
    set script_dir (realpath (dirname (status -f)))
    if test ! "$fish_tmux_iterm2" = true && test -e "$fish_tmux_config"
        set _fish_tmux_fixed_config "$script_dir/tmux.extra.conf"
    else
        set _fish_tmux_fixed_config "$script_dir/tmux.only.conf"
    end

    # wrapper starts here
    if test (count $argv) -gt 0
        command tmux $argv
        return $status
    end

    set tmux_cmd tmux
    test "$fish_tmux_iterm2" = true && set -a tmux_cmd -CC
    test "$fish_tmux_unicode" = true && set -a tmux_cmd -u

    test "$fish_tmux_detached" = true && set _detached "-d"

    if test "$fish_tmux_autoname_session" = true
        # name the session after the basename of current directory
        set session_name (basename $PWD)
        # if the current directory is the home directory, name it 'HOME'
        test "$PWD" = "$HOME" && set session_name HOME
        # if the current directory is the root directory, name it 'ROOT'
        test "$PWD" = "/" && set session_name ROOT
    else
        set session_name "$fish_tmux_default_session_name"
    end

    # try to connect to an existing session
    if test -n "$session_name"
        if test "$fish_tmux_autoconnect" = true
            $tmux_cmd attach $_detached -t $session_name
        end
    else
        if test "$fish_tmux_autoconnect" = true
            $tmux_cmd attach $_detached
        end
    end

    # if failed, just run tmux, fixing the TERM variable if requested
    if test $status -ne 0
        if test "$fish_tmux_fixterm" = true
            set -a tmux_cmd -f $_fish_tmux_fixed_config
        else if test -e "$fish_tmux_config"
            set -a tmux_cmd -f $fish_tmux_config
        end

        if test -n "$session_name"
            $tmux_cmd new-session -s $session_name
        else
            $tmux_cmd new-session
        end
    end

    if test "$fish_tmux_autoquit" = true
        kill $fish_pid
    end
end

alias tmux=_fish_tmux_plugin_run

function _fish_tmux_directory_session
    # current directory without leading path
    set dir (basename $PWD)
    # md5 hash for the full working directory path
    set md5 (echo -n $PWD | md5sum | cut -d ' ' -f 1)
    # human friendly unique session name for this directory
    set session_name "$dir"-(string shorten --char="" --max 6 $md5)
    # create or attach to the session
    tmux new -As "$session_name"
end

alias tds=_fish_tmux_directory_session

# this will autostart tmux if $fish_tmux_autostart is set to `true` using the `--on-variable` function option
function _fish_tmux_plugin_run_autostart --on-variable fish_tmux_autostart
    if test "$fish_tmux_autostart" = true && \
    test -z "$TMUX" && \
    test -z "$INSIDE_EMACS" && \
    test -z "$EMACS" && \
    test -z "$VIM" && \
    test -z "$NVIM" && \
    test -z "$INTELLIJ_ENVIRONMENT_READER" && \
    test -z "$VSCODE_RESOLVING_ENVIRONMENT" && \
    test "$TERM_PROGRAM" != 'vscode' && \
    test "$TERM_PROGRAM" != 'zed' && \
    test "$TERMINAL_EMULATOR" != 'JetBrains-JediTerm'
        set -q fish_tmux_autostart_once || set fish_tmux_autostart_once true

        if test "$fish_tmux_autostart_once" = false || test ! "$fish_tmux_autostarted" = true
            set -gx fish_tmux_autostarted true
            _fish_tmux_plugin_run
        end
    end
end
