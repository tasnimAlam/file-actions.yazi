#!/usr/bin/env bash
set -e
IFS=$'\t'

desktop="$HOME/Desktop"
created=()

for file in $selection; do
	base="$(basename "${file%.*}")"
	output="$desktop/$base"
	tesseract "$file" "$output" 2>/dev/null
	created+=("${output}.txt")
done

echo "Created: $(IFS=', '; echo "${created[*]}")"
