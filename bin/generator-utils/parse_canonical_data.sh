#!/usr/bin/env bash

function fill_test_file_with_canonical_data() {
    local slug=$1
    local test_dir=$2
    # fetches canonical_data
    canonical_json=$(curl https://raw.githubusercontent.com/exercism/problem-specifications/main/exercises/"$slug"/canonical-data.json)

    if [ "${canonical_json}" == "404: Not Found" ]; then
        canonical_json=$(jq --null-input '{cases: []}')

        cat <<EOT >>"$test_dir"

// This exercise doesn't have a canonical data file, which means you need to come up with tests
// If you came up with excellent tests, consider contributing to this repo:
// https://github.com/exercism/problem-specifications/tree/main/exercises/${slug}
EOT
    fi

    # sometimes canonical data has multiple levels with multiple `cases` arrays.
    # this "flattens" it
    cases=$(echo "$canonical_json" | jq '[ .. | objects | with_entries(select(.key | IN("uuid", "description", "input", "expected"))) | select(. != {}) | select(has("uuid")) ]')

    first_iteration=true
    jq -c '.[]' <<<"$cases" | while read -r case; do
        desc=$(echo "$case" | jq '.description' | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_' | sed 's/^/test_/')
        input=$(echo "$case" | jq '.input')
        expected=$(echo "$case" | jq '.expected')

        cat <<EOT >>"$test_dir"
#[test] $([[ "$first_iteration" == false ]] && printf "\n#[ignore]")
fn ${desc}(){
    /*

    Input:
    ${input}

    Expected output:
    ${expected}

    */

    // TODO: Add assertion
    assert_eq!(1, 1)
}

EOT
        first_iteration=false
    done
}
