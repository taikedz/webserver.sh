$%function util:content_type(f) {
	local x="$(file "$f" --mime-type)"
	echo "${x#$f: }"
}

$%function util:pid_for(procname procport) {
	ss -tunlp | grep -oP "LISTEN.+?:$procport\s.+?users:\(\(\"$procname\",pid=[0-9]+" | sed -r 's/.+?=([0-9]+)$/\1/'
}

util:mktemp() {
	local tfile="$(mktemp "$@")"
	chmod 600 "$tfile"
	echo "$tfile"
}

$%function util:haslines(filename) {
	[[ "$(grep -Pc ^ "$filename")" -gt 0 ]]
}

$%function util:firstline(filename) {
	head -n 1 "$filename"
}

$%function util:hasperm(filename) {
	ls "$filename" 2>&1 | grep -qv "Permission denied"
}

util:killnc() {
    local ncpid="$(ps|grep -P '\bnc\b'|grep -Po '^[0-9]+')"
    [[ -n "$ncpid" ]] || return
    
    ps | grep -P '\bnc\b'
    
    (set -x
        kill $ncpid
    )
}

util:killconn() {
	[[ -n "${WEBSH_connid:-}" ]] || return
	kill "$WEBSH_connid"

}

util:cleanup() {
	util:killconn
    safe:glob on
	rm .wsh-* 2>/dev/null || :
}
