userfunction:run() {
    local funcname operation target gtest output

    output="${1:-}"; shift || out:fail "Internal error - userfunction:run no output pipe defined"
    target="${1:-}" ; shift || out:fail "Internal error - userfunction:run no target function defined"

    gtest=(grep -P "^${target}\s" "functions.txt")

    [[ -f "functions.txt" ]] || {
        log:info "No functions file"
        http:respond "$output" 404 "Function unknown" <( echo "Unknown function $target" )
    }

    case "$("${gtest[@]}" | wc -l)" in
    0)
        http:respond "$output" 404 "Function unknown" <( echo "Unknown function $target" )
        ;;
    1)
        out:info "Retrieving function definition"
        read funcname operation < <("${gtest[@]}")
        out:info "Sending result"
        http:respond "$output" 200 "Running function $funcname" <(bash <(echo "$operation") 2>&1)
        ;;
    *)
        http:respond "$output" 400 "Multiple function entires" <(echo "The function file provides too many identical keys")
        ;;
    esac
}
