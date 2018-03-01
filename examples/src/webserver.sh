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

#%include out.sh args.sh log.sh autohelp.sh runmain.sh

set -euo pipefail

WEBSH_default_port=8080
WEBSH_default_logfile="./webserver-sh.log"

#%include util.sh conn.sh http.sh

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

	if args:has --verbose "$@"; then
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
