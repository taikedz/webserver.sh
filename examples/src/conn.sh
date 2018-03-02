#%include abspath.sh out.sh log.sh

conn:listen() {
	local input="$1"; shift
	local output="$1"; shift

	tail -f "$output" | nc -l "$webport" > "$input" &
	WEBSH_connid="$!"
}

conn:respond() {
	local input="$1"; shift
	local output="$1"; shift
	local target="$(http:unescape_path "$1")"; shift
	local requested_path="$(http:get_path "$input")"

	out:info "Client asked for: $requested_path -> $target"

	if [[ -e "$target" ]] && ! util:hasperm "$target"; then
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

	out:debug "Listening process: $WEBSH_connid"

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
