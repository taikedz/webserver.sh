
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

