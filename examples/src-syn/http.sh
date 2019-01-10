
$%function http:respond(output code message target) {
	# Handle a temporary file descriptor
	if [[ "$target" =~ ^/dev/fd/ ]]; then
        log:debug "Got a file descriptor $target"
		local temptarget="$(util:mktemp .wsh-XXXX)"
		cat "$target" > "$temptarget"
		target="$temptarget"
	fi
	
	# These operations try to read the file, so we do it
	#   AFTER we've checked for file descriptor
	local ctype="$(util:content_type "$target")"

    if [[ "$ctype" =~ empty ]]; then
        echo "(empty)" > "$target"
        ctype="text/plain"
    fi

	local clength="$(stat --printf="%s" "$target")"

	echo -e -n "HTTP/1.1 $code $message\r\nContent-Type: $ctype\r\nContent-Length: $clength\r\n\r\n" >> "$output"
	cat "$target" >> "$output"

	if [[ -n "${temptarget:-}" ]]; then
		rm "$temptarget"
	fi
}

$%function http:get_path(rawpath) {
	[[ "$(util:firstline "$rawpath")" =~ GET\ ([^ ]+) ]]

	echo "${BASH_REMATCH[1]:-}"
}

$%function http:unescape_path(path) {
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
