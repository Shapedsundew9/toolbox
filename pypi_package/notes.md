# Make a PyPi Package

[PyPi documentation](https://packaging.python.org/en/latest/tutorials/packaging-projects/)

```bash
mkdir docs
mkdir tests
mkdir logs
cp -r ~/Projects/text-token/.github .
cp ~/Projects/text-token/tests/__init__.py tests/
cp ~/Projects/text-token/tests/test_code_quality.py tests/
cp ~/Projects/text-token/.coveragerc .
cp ~/Projects/text-token/.pylintrc .
cp ~/Projects/text-token/MANIFEST.in .
cp ~/Projects/text-token/LICENSE .
cp ~/Projects/text-token/pyproject.toml .
cp ~/Projects/text-token/pytest.ini .
cp ~/Projects/text-token/requirements.txt .
cp -r ~/Projects/text-token/text_token/__init__.py src-folder/
```


- Then replace in files 'text-token' with the package name and 'text_token' with the module name.
- Edit the __pyproject.toml__ 'description' and other fields as necessary.
- Edit __requirements.txt__

