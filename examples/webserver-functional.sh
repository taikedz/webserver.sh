#!/bin/bash

set -euo pipefail

util:haslines() {
	[[ "$(grep -Pc ^ "$1")" -gt 0 ]]
}

util:firstline() {
	head -n 1 "$1"
}

util:killconn() {
	kill -9 "$conn_id"
}
trap util:killconn EXIT

conn:listen() {
	local input
	local output
	local pidfile
	input="$1"; shift
	output="$1"; shift
	pidfile="$1"; shift

	tail -f "$output" | nc -l 8080 > "$input" &
	echo "$!" > "$pidfile"
}

http:respond() {
	local output
	local code_message
	local target
	output="$1"; shift
	code_message="$1 $2"; shift; shift
	target="$1"; shift

	echo -e "HTTP/1.1 $code_message\r\nContent-Type: text/plain\r\nContent-Length: $(stat --printf="%s" "$target")\r\n\r\n" "$output"
	cat "$target" >> "$output"
}

conn:respond() {
	local input
	local output
	local target
	input="$1"; shift
	output="$1"; shift
	target="$1"; shift

	cat "$input"

	if [[ -f "$target" ]]; then
		http:respond "$output" 200 OK "$target"
	else
		http:respond "$output" 400 "No good" <(echo "File not found !")
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

	echo "Listening process: $conn_id"
	while ! util:haslines "$input"; do
		sleep 2
	done

	echo "Got a connection $(date)"

	[[ "$(util:firstline "$input")" =~ GET\ ([^ ]+) ]]

	conn:respond "$input" "$output" "$PWD/${BASH_REMATCH[1]}"

	rm "$input" "$output" "$pidfile"
	kill -9 "$conn_id"
}

main() {
	while true; do
		conn:open
	done
}

main "$@" >> ./webserver-sh.log
