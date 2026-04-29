#!/usr/bin/env bash
IFS=$'\t'

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Filter only image files from selection
image_files=()
for file in $selection; do
	mime=$(file -bL --mime-type "$file")
	if [[ "$mime" == image/* ]]; then
		image_files+=("$file")
	fi
done

if [ "${#image_files[@]}" -eq 0 ]; then
	echo "No image files found in selection" >&2
	exit 1
fi

output_dir=$(dirname "${image_files[0]}")
output_path="${output_dir}/${output_name}"

magick "${image_files[@]}" \
	-quality 85 \
	-units PixelsPerInch \
	-density 150 \
	"$output_path"
