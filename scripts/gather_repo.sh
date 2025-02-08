#!/usr/bin/bash
# Gather all the text files in a python repo into a single text file
# This can then be loaded into AI

echo "The contents of this file is the concatenation of all the text files within a python based git repo" > gathered.txt
echo "The start of each file is marked by 3 blank lines and a line of ~~~~, followed by a line starting" >> gathered.txt
echo "with \"Next file: \" and the relative path of the file in the repo and another blank line. The next" >> gathered.txt
echo "line is the first line of the contents of the file." >> gathered.txt
find . \( -name "*.py" -o -name "*.md" -o -name "*.json" \) -print0 | while IFS= read -r -d '' file; do 
    printf '\n\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\nNext file: %s\n\n' "$file"
    cat "$file"
done >> gathered.txt