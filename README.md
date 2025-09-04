# ons-dsc-cloudbuild-utils

## Setup Instructions

### 1. Set up Python environment and dependencies

```sh
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 2. Set up pre-commit hooks

Install the hooks for code and commit message checks:

```sh
pre-commit install
pre-commit install --hook-type commit-msg
```

This will enable checks for trailing whitespace, YAML/JSON syntax, large files, secrets, private keys, and enforce conventional commit messages.

### 3. Run pre-commit manually (optional)

You can run all checks on all files at any time:

```sh
pre-commit run --all-files
```
