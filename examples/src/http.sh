
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
		out:debug "Find code $code"
		path="$(echo "$path" | sed "s|$code|$(echo "$code"|xxd -r -p)|g")"
		code="$(http:find_code "$path")"
	done
	echo "$path"
}

http:find_code() {
	echo "$1" | grep -Po "%.."|head -n 1 || :
}
