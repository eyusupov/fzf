function __fzf_open -d "Open files and directories."
    function __fzf_open_get_open_cmd -d "Find appropriate open command."
        if type -q xdg-open
            echo "xdg-open"
        else if type -q open
            echo "open"
        end
    end

    set -l commandline (__fzf_parse_commandline)
    set -l dir $commandline[1]
    set -l fzf_query $commandline[2]

    if not type -q argparse
        set created_argparse
        function argparse
            functions -e argparse # deletes itself
        end
        if contains -- --editor $argv; or contains -- -e $argv
            set _flag_editor "yes"
        end
        if contains -- --preview $argv; or contains -- -p $argv
            set _flag_preview "yes"
        end
    end

    set -l options "e/editor" "p/preview=?" "c/custom=?"
    argparse $options -- $argv

    set -l preview_cmd
    if set -q FZF_ENABLE_OPEN_PREVIEW
        set preview_cmd "--preview-window=right:wrap --preview='fish -c \"__fzf_complete_preview {}\"'"
    end

    set -l command
    if set -q _flag_custom
        set command $_flag_custom
    else if set -q FZF_OPEN_COMMAND
        set command $FZF_OPEN_COMMAND
    else
        set command "
        command find -L \$dir -mindepth 1 \\( -path \$dir'*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' \\) -prune \
        -o -type f -print \
        -o -type d -print \
        -o -type l -print 2> /dev/null | sed 's@^\./@@'"
    end

    set -l select (eval "$command| "(__fzfcmd) $preview_cmd "-m $FZF_DEFAULT_OPTS $FZF_OPEN_OPTS --query \"$fzf_query\"" | string escape)

    # set how to open
    set -l open_cmd
    if set -q _flag_editor
        set open_cmd "$EDITOR"
    else
        set open_cmd (__fzf_open_get_open_cmd)
        if test -z "$open_cmd"
            echo "Couldn't find appropriate open command to use. Do you have 'xdg-open' or 'open' installed?"; and return 1
        end
    end

    set -l open_status 0
    if not test -z "$select"
        commandline "$open_cmd $select"; and commandline -f execute
        set open_status $status
    end

    commandline -f repaint
    return $open_status
end
