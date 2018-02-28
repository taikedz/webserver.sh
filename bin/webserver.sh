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

#!/bin/bash

#!/bin/bash

### Colours for bash Usage:bbuild
# A series of colour flags for use in outputs.
#
# Example:
# 	
# 	echo "${CRED}Some red text ${CBBLU} some blue text $CDEF some text in the terminal's default colour"
#
# Colours available:
#
# CDEF -- switches to the terminal default
#
# CRED, CBRED -- red, bold red
# CGRN, CBGRN -- green, bold green
# CYEL, CBYEL -- yellow, bold yellow
# CBLU, CBBLU -- blue, bold blue
# CPUR, CBPUR -- purple, bold purple
#
###/doc

export CRED="\033[0;31m"
export CGRN="\033[0;32m"
export CYEL="\033[0;33m"
export CBLU="\033[0;34m"
export CPUR="\033[0;35m"
export CBRED="\033[1;31m"
export CBGRN="\033[1;32m"
export CBYEL="\033[1;33m"
export CBBLU="\033[1;34m"
export CBPUR="\033[1;35m"
export CDEF="\033[0m"

### Console output handlers Usage:bbuild
#
# Write data to console stderr using colouring
#
###/doc

### Environment Variables Usage:bbuild
#
# MODE_DEBUG : set to 'true' to enable debugging output
# MODE_DEBUG_VERBOSE : set to 'true' to enable command echoing
#
###/doc

: ${MODE_DEBUG=false}
: ${MODE_DEBUG_VERBOSE=false}

### out:debug MESSAGE Usage:bbuild
# print a blue debug message to stderr
# only prints if MODE_DEBUG is set to "true"
###/doc
function out:debug {
	if [[ "$MODE_DEBUG" = true ]]; then
		echo -e "${CBBLU}DEBUG:$CBLU$*$CDEF" 1>&2
	fi
}

### out:info MESSAGE Usage:bbuild
# print a green informational message to stderr
###/doc
function out:info {
	echo -e "$CGRN$*$CDEF" 1>&2
}

### out:warn MESSAGE Usage:bbuild
# print a yellow warning message to stderr
###/doc
function out:warn {
	echo -e "${CBYEL}WARN:$CYEL $*$CDEF" 1>&2
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
		ERCODE="$1"; shift
	fi

	echo -e "${CBRED}ERROR FAIL:$CRED$*$CDEF" 1>&2
	exit $ERCODE
}

### out:dump Usage:bbuild
#
# Dump stdin contents to console stderr. Requires debug mode.
#
# Example
#
# 	action_command 2>&1 | out:dump
#
###/doc

function out:dump {
	echo -e -n "${CBPUR}$*" 1>&2
	echo -e -n "$CPUR" 1>&2
	cat - 1>&2
	echo -e -n "$CDEF" 1>&2
}

### out:break MESSAGE Usage:bbuild
#
# Add break points to a script
#
# Requires debug mode set to true
#
# When the script runs, the message is printed with a propmt, and execution pauses.
#
# Type `exit`, `quit` or `stop` to stop the program. If the breakpoint is in a subshell,
#  execution from after the subshell will be resumed.
#
# Press return to continue execution.
#
###/doc

function out:break {
	[[ "$MODE_DEBUG" = true ]] || return

	read -p "${CRED}BREAKPOINT: $* >$CDEF " >&2
	if [[ "$REPLY" =~ quit|exit|stop ]]; then
		out:fail "ABORT"
	fi
}

[[ "$MODE_DEBUG_VERBOSE" = true ]] && set -x || :
#!/bin/bash

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
	local seek="$1"; shift

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
	local token="$1"; shift
	while [[ -n "$*" ]]; do
		local item="$1"; shift

		if [[ "$item" = "$token" ]]; then
			echo "$1"
			return
		fi
	done
	return 1
}

function args:get_long {
	local token="$1"; shift
	local tokenpat="^$token=(.*)$"

	for item in "$@"; do
		if [[ "$item" =~ $tokenpat ]]; then
			echo "${BASH_REMATCH[1]}"
			return
		fi
	done
	return 1
}

### args:has TOKEN ARGS ... Usage:bbuild
#
# Determines whether TOKEN is present on its own in ARGS
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
	local token="$1"; shift
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
#	myargs=(one two -- three "four and" five)
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
	local token="$1"; shift
	
	local current_token="$1"; shift
	while [[ "$#" -gt 0 ]] && [[ "$current_token" != "$token" ]]; do
		current_token="$1"; shift
	done

	RETARR_ARGSAFTER=("$@")
}
#!/bin/bash

### Logging facility Usage:bbuild
#
# By default, writes to <stderr>
#
###/doc

BBLOGFILE=/dev/stderr
LOGENTITY=$(basename "$0")

### LOG_LEVEL Usage:bbuild
#
# Log level environment variable. Set it to one of the predefined values:
#
# $LOG_LEVEL_FAIL - failures only
# $LOG_LEVEL_WARN - failures and warnings
# $LOG_LEVEL_INFO - failures, warnings and information
# $LOG_LEVEL_DEBUG - failures, warnings, info and debug
#
# Example:
#
# 	export LOG_LEVEL=$LOG_LEVEL_WARN
# 	command ...
#
###/doc

LOG_LEVEL=0

LOG_LEVEL_FAIL=0
LOG_LEVEL_WARN=0
LOG_LEVEL_INFO=0
LOG_LEVEL_DEBUG=0

# Handily determine that the minimal level threshold is met
function log:islevel {
	local req_level="$1"; shift

	[[ "$LOG_LEVEL" -ge "$req_level" ]]
}

### log:use_file LOGFILE Usage:bbuild
# Set the specified file as log file.
#
# If this fails, log is sent to stderr
###/doc
function log:use_file {
	local target_file="$1"; shift
	local standard_outputs="/dev/(stdout|stderr)"
	if [[ ! "$target_file" =~ $standard_outputs ]]; then

		echo "$LOGENTITY $(date +"%F %T") Selecting log file" >> "$target_file" || {
			local msg="Could not set the log file to [$target_file] ; moving to stderr"

			if [[ "$BBLOGFILE" != /dev/stderr ]]; then
				# leave a trace of this in the last log file
				log:warn "$msg"
			fi

			export BBLOGFILE=/dev/stderr
			log:warn "$msg"
		}
	fi
	export BBLOGFILE="$target_file"
}

### log:use_cwd Usage:bbuild
# Create a log file in the curent working directory
###/doc
function log:use_cwd {
	log:use_file "$PWD/$LOGENTITY.log"
}

### log:use_var Usage:bbuild
# Set the log location to /var/log/$SCRIPTNAME/...
#
# prints the log file in use to stderr
###/doc
function log:use_var {
	local logdir="/var/log/$LOGENTITY"
	local logfile="$(whoami)-$UID-$HOSTNAME.log"
	local tgtlog="$logdir/$logfile"

	mkdir -p "$(dirname "$tgtlog")" && touch "$tgtlog" || {
		log:use_file "/dev/stderr"
		out:warn "Could not create [$logfile] in [$logdir] - logging to stderr"
		return 1
	}

	log:use_file "$tgtlog"
}

### log:debug MESSAGE Usage:bbuild
# Print a debug message to the log
###/doc
function log:debug {
	log:islevel "$LOG_LEVEL_DEBUG" || return

	if [[ "$MODE_DEBUG" = yes ]]; then
		echo -e "$LOGENTITY $(date "+%F %T") DEBUG: $*" >>"$BBLOGFILE"
	fi
}

### log:info MESSAGE Usage:bbuild
# print an informational message to the log
###/doc
function log:info {
	log:islevel "$LOG_LEVEL_INFO" || return

	echo -e "$LOGENTITY $(date "+%F %T") INFO: $*" >>"$BBLOGFILE"
}

### log:warn MESSAGE Usage:bbuild
# print a warning message to the log
###/doc
function log:warn {
	log:islevel "$LOG_LEVEL_WARN" || return

	echo -e "$LOGENTITY $(date "+%F %T") WARN: $*" >>"$BBLOGFILE"
}

### log:fail [CODE] MESSAGE Usage:bbuild
# print a failure message to the log, and exit with CODE
# CODE must be a number
# if no code is specified, error code 127 is used
###/doc
function log:fail {
	log:islevel "$LOG_LEVEL_FAIL" || return

	local MSG=
	local ARG=
	local ERCODE=127
	local numpat='^[0-9]+$'

	if [[ "${1:-}" =~ $numpat ]]; then
		ERCODE="$1"
		shift
	fi

	echo "$LOGENTITY $(date "+%F %T") ERROR FAIL: $*" >>"$BBLOGFILE"
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
#!/bin/bash

### autohelp:print Usage:bbuild
# Write your help as documentation comments in your script
#
# If you need to output the help from a running script, call the
# `autohelp:print` function and it will print the help documentation
# in the current script to stdout
#
# A help comment looks like this:
#
#	### <title> Usage:help
#	#
#	# <some content>
#	#
#	# end with "###/doc" on its own line (whitespaces before
#	# and after are OK)
#	#
#	###/doc
#
# You can set a different comment character by setting the 'HELPCHAR' environment variable:
#
# 	HELPCHAR=%
# 	autohelp:print
#
# You can set a different help section by specifying the 'SECTION_STRING' variable
#
# 	SECTION_STRING=subsection autohelp:print
#
###/doc

HELPCHAR='#'

function autohelp:print {
	local SECTION_STRING="${1:-}"; shift
	local TARGETFILE="${1:-}"; shift
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

### automatic help Usage:main
#
# automatically call help if "--help" is detected in arguments
#
###/doc
if [[ "$*" =~ --help ]]; then
	cols="$(tput cols)"
	autohelp:print | fold -w "$cols" -s || autohelp:print
	exit 0
fi
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
	local required_name="$1"; shift
	local funcall="$1"; shift
	local scriptname="$(basename "$0")"

	if [[ "$required_name" = "$scriptname" ]]; then
		"$funcall" "$@"
	fi
}

set -euo pipefail

WEBSH_default_port=8080
WEBSH_default_logfile="./webserver-sh.log"


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
	[[ -n "$conn_id" ]] || return
	kill -9 "$conn_id"
}

conn:listen() {
	local input
	local output
	local pidfile
	input="$1"; shift
	output="$1"; shift
	pidfile="$1"; shift

	tail -f "$output" | nc -l "$webport" > "$input" &
	echo "$!" > "$pidfile"
}

conn:respond() {
	local input
	local output
	local target
	input="$1"; shift
	output="$1"; shift
	target="$1"; shift

	local requested_path="$(http:get_path "$input")"

	out:info "Client asked for: $requested_path"

	if [[ -e "$target" ]] && ! util:hasperm "$target"; then
		log:warn "Permission denied: $requested_path"
		http:respond "$output" 403 "Forbidden" <(echo "You do not have permission to access this file.")

	elif [[ ! -e "$target" ]]; then
		log:warn "Could not find: $requested_path"
		http:respond "$output" 404 "Not found" <(echo "File not found !")

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
	local input
	local output
	local target
	local pidfile
	input="$(mktemp)"
	output="$(mktemp)"
	pidfile="$(mktemp)"

	conn:listen "$input" "$output" "$pidfile"
	conn_id="$(cat "$pidfile")"

	out:debug "Listening process: $conn_id"

	while ! util:haslines "$input"; do
		sleep 2
	done

	out:info "Got a connection !"
	log:info "Received connection"

	

	local requested_path="$(http:get_path "$input")"

	if [[ -n "$requested_path" ]]; then
		conn:respond "$input" "$output" "$PWD/$requested_path"
	else
		out:fail "Could not process the request: $(util:firstline "$input" )"
		http:respond "$output" 400 "Unknown" <(echo "We cannot handle this request.")
	fi

	rm "$input" "$output" "$pidfile"
	kill -9 "$conn_id"
}

http:respond() {
	local output
	local code_message
	local target
	output="$1"; shift
	code_message="$1 $2"; shift; shift
	target="$1"; shift

	echo -e "HTTP/1.1 $code_message\r\nContent-Type: text/plain\r\nContent-Length: $(stat --printf="%s" "$target")\r\n\r\n" >> "$output"
	cat "$target" >> "$output"
}

http:get_path() {
	[[ "$(util:firstline "$1")" =~ GET\ ([^ ]+) ]]

	echo "${BASH_REMATCH[1]:-}"
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
}

main() {
	trap util:killconn EXIT

	parse_arguments "$@" || out:fail "Could not start web server - error in arguments parsing"

	out:info "Starting web server  ..."
	log:info "Starting web server on $webport"
	while true; do
		conn:open
	done
}

runmain "webserver.sh" main "$@"
