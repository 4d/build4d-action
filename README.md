# build4d-action

[![build](https://github.com/4d/build4d-action/actions/workflows/build.yml/badge.svg)](https://github.com/4d/build4d-action/actions/workflows/build.yml)
[![buildprj](https://github.com/4d/build4d-action/actions/workflows/buildprj.yml/badge.svg)](https://github.com/4d/build4d-action/actions/workflows/buildprj.yml)

Take you 4D base and compile it.

Convert compilation errors as github annotations.

## Usage
```yaml
name: build
on:
  ...

jobs:
  build:
    name: "Build on ${{ matrix.os }}"
    strategy:
      fail-fast: false
      matrix:
        os: [ macos-latest, windows-latest ]
    runs-on: ${{ matrix.os }}
    steps:
    - name: Checkout
      uses: actions/checkout@v3
    - name: Build
      uses: 4d/build4d-action@main
```

## Example base

Could be found here https://github.com/e-marchand/tool4d-action-test
