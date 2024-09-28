# Toolbox

A collection of random scripts and notes that I otherwise misplace!

## Things With No Other Place to Go

### Imagemagick

Set PNG background to white, crop & add a 20pixel border using ImageMagick

```bash
convert filename -trim -background white -alpha remove -bordercolor white -border 20x20 docs/init_flow.png
```

### Pytest

Running coverage

```bash
cd [git-repo]
pytest --doctest-modules --junitxml=junit/test-results.xml --cov=[package] --cov-report=xml --cov-report=html --cov-config=.coveragerc --cov-branch [test(s)]
```

e.g.

```bash
cd ~/Projects/egp_physics
pytest --doctest-modules --junitxml=junit/test-results.xml --cov=egp_physics --cov-report=xml --cov-report=html --cov-config=.coveragerc --cov-branch tests/test_insertion.py
```

### Copy files to all project directories

```bash
find .. -type d -name ".git" -not -path "*/egp-types/*" -execdir cp ~/Projects/egp-types/.pylintrc . \;
```

### Move using checksum

Replace filename with file checksum to prevent collisions. No clobber & verbose.

```bash
find . -type f -execdir bash -c 'mv -nv "$1" "/home/shapedsundew9/Videos/VID_$(md5sum "$1" | cut -d" " -f1 | cut -c-8).m2ts"' _ "{}" \;
```

### Converting to MP$

```bash
find . -name "*.m2ts" -execdir bash -c 'ffmpeg -i "$1" -c:v libx264 -crf 18 "${1%.*}.mp4"' _ "{}" \;
```
