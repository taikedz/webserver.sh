#!/bin/bash

util:killconn() {
	kill -9 "$conn_id"
}
trap util:killconn EXIT

while true; do
	input="$(mktemp)"
	output="$(mktemp)"
	pidfile="$(mktemp)"

	tail -f "$output" | nc -l 8080 > "$input" &
	conn_id="$!"

	echo "Listening process: $conn_id"
	while ! [[ "$(grep -Pc ^ "$input")" -gt 0 ]] ; do
		sleep 2
	done

	echo "Got a connection $(date)"

	[[ "$(head -n 1 "$input")" =~ GET\ ([^ ]+) ]]

	cat "$input"

	if [[ -f "$target" ]]; then
		echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: $(stat --printf="%s" "$target")\r\n\r\n"
		cat "$target" >> "$output"
	else	
		echo -e "HTTP/1.1 400 No good\r\nContent-Type: text/plain\r\nContent-Length: 21\r\n\r\nFile not found!"
	fi

	rm "$input" "$output" "$pidfile"
	kill -9 "$conn_id"
done
