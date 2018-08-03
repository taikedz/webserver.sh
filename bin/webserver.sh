#!/bin/bash

### Bash Web Server Usage:help
#
# A web server written in bash !
#
# Not for use in any sane workflow, this is mainly a study on the possibility of the feat.
#
# Copy the script to a location in your $PATH and it will be available to you from anywhere.
#
# Simply run
#
# 	./webserver.sh [-p PORT] [-l LOGFILE]
#
# to serve the files in the current working directory !
#
# Serves on port 8080 by default.
#
###/doc

##bash-libs: out.sh @ 266ad599 (after 1.1.4)

##bash-libs: colours.sh @ 266ad599 (after 1.1.4)

### Colours for bash Usage:bbuild
# A series of colour flags for use in outputs.
#
# Example:
# 	
# 	echo -e "${CRED}Some red text ${CBBLU} some blue text $CDEF some text in the terminal's default colour")
#
# Requires processing of escape characters.
#
# Colours available:
#
# CRED, CBRED, HLRED -- red, bold red, highlight red
# CGRN, CBGRN, HLGRN -- green, bold green, highlight green
# CYEL, CBYEL, HLYEL -- yellow, bold yellow, highlight yellow
# CBLU, CBBLU, HLBLU -- blue, bold blue, highlight blue
# CPUR, CBPUR, HLPUR -- purple, bold purple, highlight purple
# CTEA, CBTEA, HLTEA -- teal, bold teal, highlight teal
#
# CDEF -- switches to the terminal default
# CUNL -- add underline
#
# Note that highlight and underline must be applied or re-applied after specifying a colour.
#
# If the session is detected as being in a pipe, colours will be turned off.
#   You can override this by calling `colours:check --color=always` at the start of your script
#
###/doc

##bash-libs: tty.sh @ 266ad599 (after 1.1.4)

tty:is_ssh() {
    [[ -n "$SSH_TTY" ]] || [[ -n "$SSH_CLIENT" ]] || [[ "$SSH_CONNECTION" ]]
}

tty:is_pipe() {
    [[ ! -t 1 ]]
}

### colours:check ARGS Usage:bbuild
#
# Check the args to see if there's a `--color=always` or `--color=never`
#   and reload the colours appropriately
#
###/doc
colours:check() {
    if [[ "$*" =~ --color=always ]]; then
        COLOURS_ON=true
    elif [[ "$*" =~ --color=never ]]; then
        COLOURS_ON=false
    fi

    colours:define
    return 0
}

colours:auto() {
    if tty:is_pipe ; then
        COLOURS_ON=false
    else
        COLOURS_ON=true
    fi

    colours:define
    return 0
}

colours:define() {
    if [[ "$COLOURS_ON" = false ]]; then

        export CRED=''
        export CGRN=''
        export CYEL=''
        export CBLU=''
        export CPUR=''
        export CTEA=''

        export CBRED=''
        export CBGRN=''
        export CBYEL=''
        export CBBLU=''
        export CBPUR=''
        export CBTEA=''

        export HLRED=''
        export HLGRN=''
        export HLYEL=''
        export HLBLU=''
        export HLPUR=''
        export HLTEA=''

        export CDEF=''

    else

        export CRED=$(echo -e "\033[0;31m")
        export CGRN=$(echo -e "\033[0;32m")
        export CYEL=$(echo -e "\033[0;33m")
        export CBLU=$(echo -e "\033[0;34m")
        export CPUR=$(echo -e "\033[0;35m")
        export CTEA=$(echo -e "\033[0;36m")

        export CBRED=$(echo -e "\033[1;31m")
        export CBGRN=$(echo -e "\033[1;32m")
        export CBYEL=$(echo -e "\033[1;33m")
        export CBBLU=$(echo -e "\033[1;34m")
        export CBPUR=$(echo -e "\033[1;35m")
        export CBTEA=$(echo -e "\033[1;36m")

        export HLRED=$(echo -e "\033[41m")
        export HLGRN=$(echo -e "\033[42m")
        export HLYEL=$(echo -e "\033[43m")
        export HLBLU=$(echo -e "\033[44m")
        export HLPUR=$(echo -e "\033[45m")
        export HLTEA=$(echo -e "\033[46m")

        export CDEF=$(echo -e "\033[0m")

    fi
}

colours:auto

### Console output handlers Usage:bbuild
#
# Write data to console stderr using colouring
#
###/doc

### out:info MESSAGE Usage:bbuild
# print a green informational message to stderr
###/doc
function out:info {
    echo "$CGRN$*$CDEF" 1>&2
}

### out:warn MESSAGE Usage:bbuild
# print a yellow warning message to stderr
###/doc
function out:warn {
    echo "${CBYEL}WARN: $CYEL$*$CDEF" 1>&2
}

### out:defer MESSAGE Usage:bbuild
# Store a message in the output buffer for later use
###/doc
function out:defer {
    OUTPUT_BUFFER_defer[${#OUTPUT_BUFFER_defer[@]}]="$*"
}

# Internal
function out:buffer_initialize {
    OUTPUT_BUFFER_defer=(:)
}
out:buffer_initialize

### out:flush HANDLER ... Usage:bbuild
#
# Pass the output buffer to the command defined by HANDLER
# and empty the buffer
#
# Examples:
#
# 	out:flush echo -e
#
# 	out:flush out:warn
#
# (escaped newlines are added in the buffer, so `-e` option is
#  needed to process the escape sequences)
#
###/doc
function out:flush {
    [[ -n "$*" ]] || out:fail "Did not provide a command for buffered output\n\n${OUTPUT_BUFFER_defer[*]}"

    [[ "${#OUTPUT_BUFFER_defer[@]}" -gt 1 ]] || return 0

    for buffer_line in "${OUTPUT_BUFFER_defer[@]:1}"; do
        "$@" "$buffer_line"
    done

    out:buffer_initialize
}

### out:fail [CODE] MESSAGE Usage:bbuild
# print a red failure message to stderr and exit with CODE
# CODE must be a number
# if no code is specified, error code 127 is used
###/doc
function out:fail {
    local ERCODE=127
    local numpat='^[0-9]+$'

    if [[ "$1" =~ $numpat ]]; then
        ERCODE="$1"; shift || :
    fi

    echo "${CBRED}ERROR FAIL: $CRED$*$CDEF" 1>&2
    exit $ERCODE
}

### out:error MESSAGE Usage:bbuild
# print a red error message to stderr
#
# unlike out:fail, does not cause script exit
###/doc
function out:error {
    echo "${CBRED}ERROR: ${CRED}$*$CDEF" 1>&2
}
#%import colour.sh

### Debug lib Usage:bbuild
#
# Debugging tools and functions.
#
# You need to activate debug mode using debug:activate command at the start of your script
#  (or from whatever point you wish it to activate)
#
###/doc

### Environment Variables Usage:bbuild
#
# DEBUG_mode : set to 'true' to enable debugging output
#
###/doc

: ${DEBUG_mode=false}

### debug:mode [output | /output | verbose | /verbose] ... Usage:bbuild
#
# Activate debug output (`output`), or activate command tracing (`verbose`)
#
# Deactivate with the corresponding `/output` and `/verbose` options
#
###/doc

function debug:mode() {
    local mode_switch
    for mode_switch in "$@"; do
        case "$mode_switch" in
        output)
            DEBUG_mode=true ;;
        /output)
            DEBUG_mode=false ;;
        verbose)
            set -x ;;
        /verbose)
            set +x ;;
        esac
    done
}

### debug:print MESSAGE Usage:bbuild
# print a blue debug message to stderr
# only prints if DEBUG_mode is set to "true"
###/doc
function debug:print {
    [[ "$DEBUG_mode" = true ]] || return 0
    echo "${CBBLU}DEBUG: $CBLU$*$CDEF" 1>&2
}

### debug:dump [MARKER] Usage:bbuild
#
# Pipe the data coming through stdin to stdout (as if it weren't there at all)
#
# If debug mode is on, *also* write the same data to stderr, each line preceded by MARKER
#
# Insert this function into pipes to see their output when in debugging mode
#
#   sed -r 's/linux|unix/*NIX/gi' myfile.txt | debug:dump | lprint
#
# Or use this to mask a command's output unless in debug mode
#
#   which binary 2>&1 | debug:dump >/dev/null
#
###/doc
function debug:dump {
    if [[ "$DEBUG_mode" = true ]]; then
        local MARKER="${1:-DEBUG: }"; shift || :

        cat - | sed -r "s/^/$MARKER/" | tee -a /dev/stderr
    else
        cat -
    fi
}

### debug:break MESSAGE Usage:bbuild
#
# Add break points to a script
#
# Requires `DEBUG_mode` set to true
#
# When the script runs, the message is printed with a propmt, and execution pauses.
#
# Press return to continue execution.
#
# Type `exit`, `quit` or `stop` to stop the program. If the breakpoint is in a subshell,
#  execution from after the subshell will be resumed.
#
###/doc

function debug:break {
    [[ "$DEBUG_mode" = true ]] || return 0

    echo -en "${CRED}BREAKPOINT: $* >$CDEF " >&2
    read
    if [[ "$REPLY" =~ quit|exit|stop ]]; then
        echo "${CBRED}ABORT${CDEF}"
    fi
}
##bash-libs: args.sh @ 266ad599 (after 1.1.4)

##bash-libs: patterns.sh @ 266ad599 (after 1.1.4)

### Useful patterns Usage:bbuild
#
# Some useful regex patterns, exported as environment variables.
#
# They are not foolproof, and you are encouraged to improve upon them.
#
# $PAT_blank - detects whether an entire line is empty or whitespace
# $PAT_comment - detects whether is a line is a script comment (assumes '#' as the comment marker)
# $PAT_num - detects whether the string is an integer number in its entirety
# $PAT_cvar - detects if the string is a valid C variable name
# $PAT_filename - detects if the string is a safe UNIX or Windows file name;
#   does not allow presence of whitespace or special characters aside from '_', '.', '-'
# $PAT_email - simple heuristic to determine whether a string looks like a valid email address
#
###/doc

export PAT_blank='^\s*$'
export PAT_comment='^\s*(#.*)?$'
export PAT_num='^[0-9]+$'
export PAT_cvar='^[a-zA-Z_][a-zA-Z0-9_]*$'
export PAT_filename='^[a-zA-Z0-9_.-]$'
export PAT_email="$PAT_filename@$PAT_filename.$PAT_cvar"

### args Usage:bbuild
#
# An arguments handling utility.
#
###/doc

### args:get TOKEN ARGS ... Usage:bbuild
#
# Given a TOKEN, find the argument value
#
# Typically called with the parent's arguments
#
# 	args:get --key "$@"
# 	args:get -k "$@"
#
# If TOKEN is an int, returns the argument at that index (starts at 1, negative numbers count from end backwards)
#
# If TOKEN starts with two dashes ("--"), expect the value to be supplied after an equal sign
#
# 	--token=desired_value
#
# If TOKEN starts with a single dash, and is a letter or a number, expect the value to be the following token
#
# 	-t desired_value
#
# Returns 1 if could not find anything appropriate.
#
###/doc

function args:get {
    local seek="$1"; shift || :

    if [[ "$seek" =~ $PAT_num ]]; then
        local arguments=("$@")

        # Get the index starting at 1
        local n=$((seek-1))
        # but do not affect wrap-arounds
        [[ "$n" -ge 0 ]] || n=$((n+1))

        echo "${arguments[$n]}"

    elif [[ "$seek" =~ ^--.+ ]]; then
        args:get_long "$seek" "$@"

    elif [[ "$seek" =~ ^-[a-zA-Z0-9]$ ]]; then
        args:get_short "$seek" "$@"

    else
        return 1
    fi
}

function args:get_short {
    local token="$1"; shift || :
    while [[ -n "$*" ]]; do
        local item="$1"; shift || :

        if [[ "$item" = "$token" ]]; then
            echo "$1"
            return 0
        fi
    done
    return 1
}

function args:get_long {
    local token="$1"; shift || :
    local tokenpat="^$token=(.*)$"

    for item in "$@"; do
        if [[ "$item" =~ $tokenpat ]]; then
            echo "${BASH_REMATCH[1]}"
            return 0
        fi
    done
    return 1
}

### args:has TOKEN ARGS ... Usage:bbuild
#
# Determines whether TOKEN is present on its own in ARGS
#
# Typically called with the parent's arguments
#
# 	args:has thing "$@"
#
# Returns 0 on success for example
#
# 	args:has thing "one" "thing" "or" "another"
#
# Returns 1 on failure for example
#
# 	args:has thing "one thing" "or another"
#
# "one thing" is not a valid match for "thing" as a token.
#
###/doc

function args:has {
    local token="$1"; shift || :
    for item in "$@"; do
        if [[ "$token" = "$item" ]]; then
            return 0
        fi
    done
    return 1
}

### args:after TOKEN ARGS ... Usage:bbuild
#
# Return all tokens after TOKEN via the RETARR_ARGSAFTER
#
#    myargs=(one two -- three "four and" five)
# 	args:after -- "${myargs[@]}"
#
# 	for a in "${RETARR_ARGSAFTER}"; do
# 		echo "$a"
# 	done
#
# The above prints
#
# 	three
# 	four and
# 	five
#
###/doc

function args:after {
    local token="$1"; shift || :
    
    local current_token="$1"; shift || :
    while [[ "$#" -gt 0 ]] && [[ "$current_token" != "$token" ]]; do
        current_token="$1"; shift || :
    done

    RETARR_ARGSAFTER=("$@")
}
##bash-libs: log.sh @ 266ad599 (after 1.1.4)


### Logging facility Usage:bbuild
#
# By default, writes to <stderr>
#
# Precedes all messages with the name of the script
#
# If you specify a log file with log:use_cwd or log:use_file then the log info
#  is written to the appropriate file, and not to stderr
#
# Example usage:
#
# 	log:use_file activity.log
#
# 	log:info "This is an info message"
#
###/doc

BBLOGFILE=/dev/stderr
LOGENTITY=$(basename "$0")

### LOG_LEVEL Usage:bbuild
#
# Log level environment variable, by default set to WARN level.
#
# Set it to one of the predefined values:
#
# $LOG_LEVEL_FAIL - failures only
# $LOG_LEVEL_WARN - failures and warnings
# $LOG_LEVEL_INFO - failures, warnings and information
# $LOG_LEVEL_DEBUG - failures, warnings, info and debug
#
# Example:
#
# 	export LOG_LEVEL=$LOG_LEVEL_INFO
# 	command ...
#
###/doc

LOG_LEVEL=1

LOG_LEVEL_FAIL=0
LOG_LEVEL_WARN=1
LOG_LEVEL_INFO=2
LOG_LEVEL_DEBUG=3

# Handily determine that the minimal level threshold is met
function log:islevel {
    local req_level="$1"; shift || :

    [[ "$LOG_LEVEL" -ge "$req_level" ]]
}

### log:get_level ARGS ... Usage:bbuild
#
# Pass script arguments and check for log level modifier
#
# This function will look for an argument like --log=N or --log={fail|warn|info|debug} and set the level appropriately
#
# Retuns non-zero if log level was specified but could not be determined
#
# Usage example:
#
# 	main() {
# 		log:get_level "$@" || echo "Invalid log level"
#
# 		# ... your code ...
# 	}
#
# 	main "$@"
#
###/doc

function log:get_level {
    local level="$(args:get --log "$@")"

    if [[ -z "$level" ]]; then
        return 0
    fi

    case "$level" in
    0|fail)
        LOG_LEVEL="$LOG_LEVEL_FAIL" ;;
    1|warn)
        LOG_LEVEL="$LOG_LEVEL_WARN" ;;
    2|info)
        LOG_LEVEL="$LOG_LEVEL_INFO" ;;
    3|debug)
        LOG_LEVEL="$LOG_LEVEL_DEBUG" ;;
    *)
        return 1
    esac

    return 0
}

### log:use_file LOGFILE Usage:bbuild
# Set the specified file as log file.
#
# If this fails, log is sent to stderr and code 1 is returned
###/doc
function log:use_file {
    local target_file="$1"; shift || :
    local standard_outputs="/dev/(stdout|stderr)"
    local res=0

    if [[ ! "$target_file" =~ $standard_outputs ]]; then

        echo "$LOGENTITY $(date +"%F %T") Selecting log file" >> "$target_file" || {
            res=1
            local msg="Could not set the log file to [$target_file] ; moving to stderr"

            if [[ "$BBLOGFILE" != /dev/stderr ]]; then
                # leave a trace of this in the last log file
                log:warn "$msg" || :
            fi

            export BBLOGFILE=/dev/stderr
            log:warn "$msg"
        }
    fi
    export BBLOGFILE="$target_file"
    return $res
}

### log:use_cwd Usage:bbuild
# Create a log file in the current working directory, using the current script's name
#  as a base for the log file's name
#
# If could not log in a local file, falls back to stderr and returns code 1
###/doc
function log:use_cwd {
    log:use_file "$PWD/$LOGENTITY.log"
    return "$?"
}

### log:use_var Usage:bbuild
# Set the log location to /var/log/<SCRIPTNAME>/...
#
# prints the log file in use to stderr
#
# If /var/log location cannot be accessed, tries to log to current directory
#
# If current location cannot be logged to, writes to stderr
#
# Returns code 1 if location in /var/log could not be used
###/doc
function log:use_var {
    local logdir="/var/log/$LOGENTITY"
    local logfile="$(whoami)-$UID-$HOSTNAME.log"
    local tgtlog="$logdir/$logfile"

    (mkdir -p "$logdir" && touch "$tgtlog") || {
        out:warn "Could not create [$logfile] in [$logdir] - logging locally"
        log:use_cwd
        return 1
    }

    log:use_file "$tgtlog"
}

### log:debug MESSAGE Usage:bbuild
# Print a debug message to the log
###/doc
function log:debug {
    log:islevel "$LOG_LEVEL_DEBUG" || return 0

    echo -e "$LOGENTITY $(date "+%F %T") DEBUG: $*" >>"$BBLOGFILE"
}

### log:debug:fork [MARKER] Usage:bbuild
#
# Pipe the data coming through stdin to stdout
#
# *Also* write the same data to the log when at debug level, each line preceded by MARKER
#
# Insert this debug fork into pipes to record their output
#
###/doc
function log:debug:fork {
    if log:islevel "$LOG_LEVEL_DEBUG"; then
        local MARKER="${1:-PIPEDUMP}"; shift || :
        MARKER="$(date "+%F %T") $MARKER :"

        cat - | sed -r "s/^/$MARKER/" | tee -a "$BBLOGFILE"
    else
        cat -
    fi
}

### log:info MESSAGE Usage:bbuild
# print an informational message to the log
###/doc
function log:info {
    log:islevel "$LOG_LEVEL_INFO" || return 0

    echo -e "$LOGENTITY $(date "+%F %T") INFO: $*" >>"$BBLOGFILE"
}

### log:warn MESSAGE Usage:bbuild
# print a warning message to the log
###/doc
function log:warn {
    log:islevel "$LOG_LEVEL_WARN" || return 0

    echo -e "$LOGENTITY $(date "+%F %T") WARN: $*" >>"$BBLOGFILE"
}

### log:fail [CODE] MESSAGE Usage:bbuild
# print a failure-level message to the log
###/doc
function log:fail {
    log:islevel "$LOG_LEVEL_FAIL" || return 0

    echo "$LOGENTITY $(date "+%F %T") FAIL: $*" >>"$BBLOGFILE"
}

### log:dump Usage:bbuild
#
# Dump the stdin to the log.
#
# Requires level $LOG_LEVEL_DEBUG
#
# Example:
#
# 	action_command 2>&1 | log:dump
#
###/doc

function log:dump {
    log:debug "$* -------------¬"
    log:debug "$(cat -)"
    log:debug "______________/"
}
##bash-libs: autohelp.sh @ 266ad599 (after 1.1.4)

### autohelp:print [ SECTION [FILE] ] Usage:bbuild
# Write your help as documentation comments in your script
#
# If you need to output the help from your script, or a file, call the
# `autohelp:print` function and it will print the help documentation
# in the current script to stdout
#
# A help comment looks like this:
#
#    ### <title> Usage:help
#    #
#    # <some content>
#    #
#    # end with "###/doc" on its own line (whitespaces before
#    # and after are OK)
#    #
#    ###/doc
#
# You can set a different help section by specifying a subsection
#
# 	autohelp:print section2
#
# > This would print a section defined in this way:
#
# 	### Some title Usage:section2
# 	# <some content>
# 	###/doc
#
# You can set a different comment character by setting the 'HELPCHAR' environment variable:
#
# 	HELPCHAR=%
#
###/doc

HELPCHAR='#'

function autohelp:print {
    local SECTION_STRING="${1:-}"; shift || :
    local TARGETFILE="${1:-}"; shift || :
    [[ -n "$SECTION_STRING" ]] || SECTION_STRING=help
    [[ -n "$TARGETFILE" ]] || TARGETFILE="$0"

        echo -e "\n$(basename "$TARGETFILE")\n===\n"
        local SECSTART='^\s*'"$HELPCHAR$HELPCHAR$HELPCHAR"'\s+(.+?)\s+Usage:'"$SECTION_STRING"'\s*$'
        local SECEND='^\s*'"$HELPCHAR$HELPCHAR$HELPCHAR"'\s*/doc\s*$'
        local insec=false

        while read secline; do
                if [[ "$secline" =~ $SECSTART ]]; then
                        insec=true
                        echo -e "\n${BASH_REMATCH[1]}\n---\n"

                elif [[ "$insec" = true ]]; then
                        if [[ "$secline" =~ $SECEND ]]; then
                                insec=false
                        else
                echo "$secline" | sed -r "s/^\s*$HELPCHAR//g"
                        fi
                fi
        done < "$TARGETFILE"

        if [[ "$insec" = true ]]; then
                echo "WARNING: Non-terminated help block." 1>&2
        fi
    echo ""
}

### autohelp:paged Usage:bbuild
#
# Display the help in the pager defined in the PAGER environment variable
#
###/doc
function autohelp:paged {
    : ${PAGER=less}
    autohelp:print "$@" | $PAGER
}

### autohelp:check Usage:bbuild
#
# Automatically print help and exit if "--help" is detected in arguments
#
# Example use:
#
#    #!/bin/bash
#
#    ### Some help Usage:help
#    #
#    # Some help text
#    #
#    ###/doc
#
#    #%include autohelp.sh
#
#    main() {
#        autohelp:check "$@"
#
#        # now add your code
#    }
#
#    main "$@"
#
###/doc
autohelp:check() {
    if [[ "$*" =~ --help ]]; then
        cols="$(tput cols)"
        autohelp:print | fold -w "$cols" -s || autohelp:print
        exit 0
    fi
}
##bash-libs: runmain.sh @ 266ad599 (after 1.1.4)

### runmain SCRIPTNAME FUNCTION [ARGUMENTS ...] Usage:bbuild
#
# Runs the function FUNCTION with ARGUMENTS, only if the runtime
# name of the script matches SCRIPTNAME
#
# This allows you include a main-like function in your library
# that only runs if you use your lib as an executabl itself.
#
# For example, an image archiver could be:
#
# 	function archive_images {
# 		tar czf "$1.tgz" "$@"
# 	}
#
# 	runmain archiveimages.sh archive_images "$@"
#
# When included a different script, the runmain call does not fire the lib's function
#
# If the lib is compiled/made executable, and named "archiveimages.sh", the function runs.
#
# This is similar to `if __name__ == "__main__"` clauses in python
#
###/doc

function runmain {
    local required_name="$1"; shift || :
    local funcall="$1"; shift || :
    local scriptname="$(basename "$0")"

    if [[ "$required_name" = "$scriptname" ]]; then
        "$funcall" "$@"
    fi
}

set -euo pipefail

WEBSH_default_port=8080
WEBSH_default_logfile="./webserver-sh.log"

util:content_type() {
	local f="$1"; shift
	local x="$(file "$f" --mime-type)"
	echo "${x#$f: }"
}

util:pid_for() {
	local procname="$1"; shift
	local procport="$1"; shift

	ss -tunlp | grep -oP "LISTEN.+?\*:$procport\s.+?users:\(\(\"$procname\",pid=[0-9]+" | sed -r 's/.+?=([0-9]+)$/\1/'
}

util:mktemp() {
	local tfile="$(mktemp "$@")"
	chmod 600 "$tfile"
	echo "$tfile"
}

util:haslines() {
	[[ "$(grep -Pc ^ "$1")" -gt 0 ]]
}

util:firstline() {
	head -n 1 "$1"
}

util:hasperm() {
	ls "$1" 2>&1 | grep -qv "Permission denied"
}

util:killconn() {
	[[ -n "${WEBSH_connid:-}" ]] || return
	kill "$WEBSH_connid"
}

util:cleanup() {
	util:killconn
	rm .wsh-* 2>/dev/null || :
}
##bash-libs: abspath.sh @ 266ad599 (after 1.1.4)

### abspath:path RELATIVEPATH [ MAX ] Usage:bbuild
# Returns the absolute path of a file/directory
#
# MAX defines the maximum number of "../" relative items to process
#   default is 50
###/doc

function abspath:path {
    local workpath="$1" ; shift || :
    local max="${1:-50}" ; shift || :

    if [[ "${workpath:0:1}" != "/" ]]; then workpath="$PWD/$workpath"; fi

    workpath="$(abspath:collapse "$workpath")"
    abspath:resolve_dotdot "$workpath" "$max" | sed -r 's|(.)/$|\1|'
}

function abspath:collapse {
    echo "$1" | sed -r 's|/\./|/|g ; s|/\.$|| ; s|/+|/|g'
}

function abspath:resolve_dotdot {
    local workpath="$1"; shift || :
    local max="$1"; shift || :

    # Set a limit on how many iterations to perform
    # Only very obnoxious paths should fail
    local obnoxious_counter
    for obnoxious_counter in $(seq 1 $max); do
        # No more dot-dots - good to go
        if [[ ! "$workpath" =~ /\.\.(/|$) ]]; then
            echo "$workpath"
            return 0
        fi

        # Starts with an up-one at root - unresolvable
        if [[ "$workpath" =~ ^/\.\.(/|$) ]]; then
            return 1
        fi

        workpath="$(echo "$workpath"|sed -r 's@[^/]+/\.\.(/|$)@@')"
    done

    # A very obnoxious path was used.
    return 2
}
userfunction:run() {
    local funcname operation target gtest output

    output="${1:-}"; shift || out:fail "Internal error - userfunction:run no output pipe defined"
    target="${1:-}" ; shift || out:fail "Internal error - userfunction:run no target function defined"

    gtest=(grep -P "^${target}\s" "functions.txt")

    [[ -f "functions.txt" ]] || {
        log:info "No functions file"
        http:respond "$output" 404 "Function unknown" <( echo "Unknown function $target" )
    }

    case "$("${gtest[@]}" | wc -l)" in
    0)
        http:respond "$output" 404 "Function unknown" <( echo "Unknown function $target" )
        ;;
    1)
        out:info "Retrieving function definition"
        read funcname operation < <("${gtest[@]}")
        out:info "Sending result"
        http:respond "$output" 200 "Running function $funcname" <(bash <(echo "$operation") 2>&1)
        ;;
    *)
        http:respond "$output" 400 "Multiple function entires" <(echo "The function file provides too many identical keys")
        ;;
    esac
}

conn:listen() {
	local input="$1"; shift
	local output="$1"; shift

	tail -f "$output" | nc -l "$webport" | conn:dump_headers_only > "$input" &

	WEBSH_connid="$(util:pid_for nc "$webport")"
}

conn:dump_headers_only() {
	while read; do
		if [[ "$REPLY" =~ ^\s*$ ]]; then
			break
		fi

		echo "$REPLY"
	done
}

conn:respond() {
	local input="$1"; shift
	local output="$1"; shift
	local target="$(http:unescape_path "$1")"; shift
	local requested_path="$(http:get_path "$input")"

	out:info "Client asked for: $requested_path -> $target"

	if [[ "$requested_path" =~ ^/~[a-zA-Z0-9]+$ ]]; then
        log:info "Called function ${requested_path:2}"
        out:info "Called function ${requested_path:2}"
        userfunction:run "$output" "${requested_path:2}"

    elif [[ -e "$target" ]] && ! util:hasperm "$target"; then
		log:warn "Permission denied: $requested_path"
		http:respond "$output" 403 "Forbidden" <(echo "You do not have permission to access this file.")

	elif [[ ! -e "$target" ]]; then
		log:warn "Could not find: $requested_path"
		http:respond "$output" 404 "Not found" <(echo "<html><body><h1>File not found</h1> $requested_path --> $target !</body></html>")

	elif [[ -f "$target" ]]; then
		log:info "Serving $requested_path"
		http:respond "$output" 200 OK "$target"

	elif [[ -d "$target" ]]; then
		log:info "Serving $requested_path listing"
		http:respond "$output" 200 OK <(ls -l "$target")

	else
		log:warn "Unknown request"
		http:respond "$output" 500 Error <(echo "Unknown error ...!")
	fi
}

conn:open() {
	local input="$(util:mktemp .wsh-XXXX)"
	local output="$(util:mktemp .wsh-XXXX)"
	WEBSH_connid=""

	conn:listen "$input" "$output"

	debug:print "Listening process: $WEBSH_connid"

	while ! util:haslines "$input"; do
		sleep 2
	done

	out:info "Got a connection !"
	log:info "Received connection"

	local requested_path="$(http:get_path "$input")"

	if [[ -n "$requested_path" ]]; then
		if ! abspath:path "$requested_path" >/dev/null ; then
			http:respond "$output" 403 "Forbidden" <(echo "Not permitted")
		else
			conn:respond "$input" "$output" "$(abspath:path "$PWD/$requested_path")"
		fi
	else
		out:error "Could not process the request: $(util:firstline "$input" )"
		http:respond "$output" 400 "Unknown" <(echo "We cannot handle this request.")
	fi

	util:killconn || :
	rm "$input" "$output"
}

http:respond() {
	local output="$1"; shift
	local code_message="$1 $2"; shift 2
	local target="$1"; shift

	# Handle a temporary file descriptor
	if [[ "$target" =~ ^/dev/fd/ ]]; then
		local temptarget="$(util:mktemp .wsh-XXXX)"
		cat "$target" > "$temptarget"
		target="$temptarget"
		ctype="text/plain"
	fi
	
	# These operations try to read the file, so we do it
	#   AFTER we've checked for file descriptor
	local ctype="$(util:content_type "$target")"
	local clength="$(stat --printf="%s" "$target")"

	echo -e -n "HTTP/1.1 $code_message\r\nContent-Type: $ctype\r\nContent-Length: $clength\r\n\r\n" >> "$output"
	cat "$target" >> "$output"

	if [[ -n "${temptarget:-}" ]]; then
		rm "$temptarget"
	fi
}

http:get_path() {
	[[ "$(util:firstline "$1")" =~ GET\ ([^ ]+) ]]

	echo "${BASH_REMATCH[1]:-}"
}

http:unescape_path() {
	local path="$1"; shift

	local code="$(http:find_code "$path")"
	while [[ -n "$code" ]]; do
		debug:print "Find code $code"
		path="$(echo "$path" | sed "s|$code|$(echo "$code"|xxd -r -p)|g")"
		code="$(http:find_code "$path")"
	done
	echo "$path"
}

http:find_code() {
	echo "$1" | grep -Po "%.."|head -n 1 || :
}

parse_arguments() {
	if args:has --help "$@" ; then
		autohelp:print
		exit 0
	fi

	local logname="$(args:get -l "$@")"
	webport="$(args:get -p "$@")" || webport="$WEBSH_default_port"

	[[ -n "$logname" ]] || logname="$WEBSH_default_logfile"
	log:use_file "$logname"

	if args:has --debug "$@"; then
		MODE_DEBUG=true
	fi

	if args:has --trace "$@"; then
		set -x
	fi
}

main() {
	trap util:cleanup EXIT

	parse_arguments "$@" || out:fail "Could not start web server - error in arguments parsing"

	out:info "Starting web server  ..."
	log:info "Starting web server on $webport"
	while true; do
		conn:open
	done
}

runmain "webserver.sh" main "$@"
