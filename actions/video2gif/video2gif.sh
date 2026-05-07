#!/usr/bin/env bash
set -e
IFS=$'\t'

fps="${fps:-15}"
width="${width:-480}"
file="$selection"

dir="$(dirname "$file")"
base="$(basename "${file%.*}")"
output="$dir/${base}.gif"
palette="/tmp/palette_$$.png"

# Build scale filter — skip scaling if width is -1
if [ "$width" = "-1" ]; then
	vf_base="fps=${fps}"
else
	vf_base="fps=${fps},scale=${width}:-1:flags=lanczos"
fi

# Pass 1: generate optimized palette from full video
ffmpeg -y -i "$file" \
	-vf "${vf_base},palettegen=stats_mode=full" \
	"$palette" 2>/dev/null

# Pass 2: render GIF using the palette with dithering
ffmpeg -y -i "$file" -i "$palette" \
	-lavfi "${vf_base} [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
	"$output" 2>/dev/null

rm -f "$palette"

# Further compress with gifsicle if available
if command -v gifsicle &>/dev/null; then
	gifsicle -O3 --lossy=80 -o "$output" "$output"
fi

echo "Created: $output"
