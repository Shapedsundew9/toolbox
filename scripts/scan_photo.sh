#!/usr/bin/bash
# Take a scanned 6x4 landscape photo at 300 dpi in a letter size scanned jpeg
# and convert it to a 6x4 landscape photo at 300 dpi removing the borders and edge cruft
mkdir ./output
for file in *.jpg; do
    echo "Converting photo $file"
    # Needs to be two steps as the command line options appear to interfere with each other
    convert $file -fuzz 10% -trim output.jpg
    convert output.jpg -gravity Center -crop 95%x95% -resize "1800x1200^" -extent 1800x1200 ./output/$file
done