util:content_type() {
	local f="$1"; shift
	local x="$(file "$f" --mime-type)"
	echo "${x#$f: }"
}

util:pid_for() {
	local procname="$1"; shift
	local procport="$1"; shift

	ss -tunlp | grep -oP "LISTEN.+?\*:$procport\s.+?users:\(\(\"$procname\",pid=[0-9]+" | sed -r 's/.+?=([0-9]+)$/\1/'
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
	kill "$WEBSH_connid"
}

util:cleanup() {
	util:killconn
	rm .wsh-* 2>/dev/null || :
}
