$%function userfunction:run(output target) {
    local funcname operation gtest

    gtest=(grep -P "^${target}\\s" "functions.txt")

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

        safe:space-split on
        read funcname operation < <("${gtest[@]}")
        safe:space-split off

        log:debug "Operation: $operation"
        debug:print "Operation: $operation"
        out:info "Sending result"
        http:respond "$output" 200 "Running function $funcname" <(bash <(echo "$operation") 2>&1)
        ;;
    *)
        http:respond "$output" 400 "Multiple function entires" <(echo "The function file provides too many identical keys")
        ;;
    esac
}
