util:content_type() {
	local f="$1"; shift
	local x="$(file "$f" --mime-type)"
	echo "${x#$f: }"
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
	kill -9 "$WEBSH_connid"
}

util:cleanup() {
	util:killconn
	rm .wsh-* 2>/dev/null || :
}
