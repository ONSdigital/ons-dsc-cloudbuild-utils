# ons-dsc-cloudbuild-utils

[![CI](https://github.com/ONSdigital/ons-dsc-cloudbuild-utils/actions/workflows/ci.yml/badge.svg)](https://github.com/ONSdigital/ons-dsc-cloudbuild-utils/actions/workflows/ci.yml)
[![pre-commit enabled](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://pre-commit.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.12](https://img.shields.io/badge/python-3.12-blue.svg)](https://www.python.org/downloads/release/python-3120/)

Utilities and helpers for Google Cloud Build automation, including bash scripts and YAML workflows. Ensures best practices for authentication, secrets detection, and commit message standards.

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
