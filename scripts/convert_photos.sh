#!/usr/bin/bash
# Rotate photos to landscape as necessary and convert to 6x4 adding a white border
mkdir ./output
for file in *.jpg; do
    echo "Converting photo $file"
    convert $file -resize 4608x3072 -background white -gravity center -extent 4608x3072 ./output/$file
done
