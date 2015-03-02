#!/usr/bin/env bash

CONFIG_DIR="${HOME}/.config"
ST_CONFIG="${CONFIG_DIR}/sublime-text-3"
ST_CONFIG_BACKUP="${ST_CONFIG}.bak"
ST_EXEC="sublime_text"

SCRIPT=$0
CMD=$1
PROFILE_NAME=$2

USER_SETTINGS=$'{
    "atomic_save": false,
    "caret_style": "phase",
    "bold_folder_labels": true,
    "font_face": "Monospace",
    "font_size": 11,
    "highlight_line": true,
    "highlight_modified_tabs": true,
    "ignored_packages":
    [
        "ASP",
        "Go",
        "Batch File",
        "OCaml",
        "Groovy",
        "TCL",
        "Perl",
        "Lisp",
        "Scala",
        "R",
        "PHP",
        "ActionScript",
        "Matlab",
        "Pascal",
        "Graphviz",
        "Ruby",
        "Erlang",
        "C#",
        "AppleScript",
        "Rails",
        "Objective-C",
        "LaTeX",
        "Haskell",
        "Java",
        "Vintage"
    ],
    "line_padding_bottom": 1,
    "line_padding_top": 1,
    "rulers":
    [
        80
    ],
    "save_on_focus_lost": true,
    "translate_tabs_to_spaces": true,
    "trim_trailing_white_space_on_save": true
}'

usage() {
    echo $"Usage: $SCRIPT {create|run} <profile_name>"
}

echo_err() {
    >&2 echo -e $1
}

finish() {
    # rollback to the default configuration
    local PROFILE_DIR="${ST_CONFIG}.${PROFILE_NAME}"
    mv $ST_CONFIG $PROFILE_DIR
    if [[ -d $ST_CONFIG_BACKUP ]]; then
        mv $ST_CONFIG_BACKUP $ST_CONFIG
    fi
    echo $"[$SCRIPT] Clean up ;)"
}
trap finish EXIT

#Check whether Sublime Text is installed
ST_PATH=$(command -v $ST_EXEC)
if [[ ! ST ]]; then
    echo_err "Have you installed Sublime Text 3?"
    exit 251
fi

# Check whether Sublime Text is running
ST_PID=$(pgrep $ST_EXEC)
if [[ $ST_PID ]] ; then
    echo_err "Sublime Text is running [pid: $ST_PID]! \
              Please quit and re-run with $SCRIPT"
    exit 253
fi

if [[ !($CMD && $PROFILE_NAME) ]]; then
    echo_err "Mandatory parameters are missing!"
    usage
    exit 254
fi

case "$CMD" in
    create)
        PROFILE_DIR="${ST_CONFIG}.${PROFILE_NAME}"
        if [[ -d $PROFILE_DIR ]]; then
            echo_err "'$PROFILE_NAME' already exists!"
            exit 252
        fi
        echo -n "Creating a new profile '$PROFILE_NAME'... "
        mkdir ${PROFILE_DIR} && mkdir "${PROFILE_DIR}/Installed Packages"

        PACKAGES="${PROFILE_DIR}/Packages"
        USER="${PROFILE_DIR}/Packages/User"
        mkdir $PACKAGES
        mkdir $USER
        echo $USER_SETTINGS > "${USER}/Preferences.sublime-settings"

        echo "Done"
        ;;
    run)
        PROFILE_DIR="${ST_CONFIG}.${PROFILE_NAME}"
        if [[ ! -d $PROFILE_DIR ]]; then
            echo_err "'$PROFILE_NAME' doesn't exist!"
            exit 252
        fi

        # Backup current config (if exists)
        if [[ -d $ST_CONFIG ]]; then
            mv $ST_CONFIG $ST_CONFIG_BACKUP
        fi

        # Swap profiles
        mv $PROFILE_DIR $ST_CONFIG

        # Run ST editor
        $ST_EXEC
        sleep 0.5
        ST_PID=$(pgrep $ST_EXEC)
        while [[ -e "/proc/${ST_PID}" ]]; do sleep 0.1; done
        ;;
    *)
        echo_err "Unknown command '${CMD}'"
        usage
        exit 254
        ;;
esac

