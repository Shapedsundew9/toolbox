# Make a PyPi Package

[PyPi documentation](https://packaging.python.org/en/latest/tutorials/packaging-projects/)

```bash
mkdir docs
mkdir tests
mkdir logs
cp -r ../pypgtable/.github .
cp -r ../pypgtable/pypgtable/__
cp -r ../pypgtable/pypgtable/__init__.py text_token/
cp ../pypgtable/tests/__init__.py tests/
cp ../pypgtable/tests/test_code_quality.py tests/
cp ../pypgtable/.coveragerc .
cp ../pypgtable/.pylintrc .
cp ../pypgtable/MANIFEST.in .
cp ../pypgtable/LICENSE .
cp ../pypgtable/pyproject.toml .
cp ../pypgtable/pytest.ini .
cp ../pypgtable/requirements.txt .
cp ../pypgtable/setup* .
```

