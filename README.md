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
