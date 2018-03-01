#%include abspath.sh out.sh log.sh

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
	local requested_path
	input="$1"; shift
	output="$1"; shift
	target="$1"; shift

	requested_path="$(http:get_path "$input")"

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
	local requested_path
	input="$(mktemp .wsh-XXXX)"
	output="$(mktemp .wsh-XXXX)"
	pidfile="$(mktemp .wsh-XXXX)"

	conn:listen "$input" "$output" "$pidfile"
	conn_id="$(cat "$pidfile")"

	out:debug "Listening process: $conn_id"

	while ! util:haslines "$input"; do
		sleep 2
	done

	out:info "Got a connection !"
	log:info "Received connection"

	requested_path="$(http:get_path "$input")"

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
	rm "$input" "$output" "$pidfile"
}
