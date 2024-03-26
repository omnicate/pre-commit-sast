#!/bin/bash

# Initialize a variable for additional Trivy arguments
TRIVY_ARGS=""

# Function to add arguments to TRIVY_ARGS
add_arg() {
    local key=$1
    local value=$2
    TRIVY_ARGS+=" $key $value"
}

# Loop through arguments to build TRIVY_ARGS
while [[ $# -gt 0 ]]; do
    case "$1" in
        --args=*)
            IFS='=' read -r _ value <<< "$1"
            # Split the value into two parts: key and value
            IFS=' ' read -r key arg_value <<< "$value"
            add_arg "$key" "$arg_value"
            ;;
        *)
            # Assume it's a file path
            break
            ;;
    esac
    shift
done

OVERALL_EXIT_STATUS=0

# Remaining arguments are treated as files
for file in "$@"; do
    if [[ -f "$file" ]]; then
        echo "Scanning file: $file"
        EXIT_STATUS=0
        trivy conf $TRIVY_ARGS --exit-code 1 "$file" || EXIT_STATUS=$?
        if [ "$EXIT_STATUS" -ne 0 ]; then
            OVERALL_EXIT_STATUS=$EXIT_STATUS
        fi
    fi
done

exit $OVERALL_EXIT_STATUS
