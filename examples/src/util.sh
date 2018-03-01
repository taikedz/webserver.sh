
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
	[[ -n "${conn_id:-}" ]] || return
	kill -9 "$conn_id"
}

util:cleanup() {
	util:killconn
	rm .wsh-* 2>/dev/null || :
}
