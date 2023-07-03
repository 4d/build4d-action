# build4d-action

[![build](https://github.com/4d/build4d-action/actions/workflows/build.yml/badge.svg)](https://github.com/4d/build4d-action/actions/workflows/build.yml)
[![buildprj](https://github.com/4d/build4d-action/actions/workflows/buildprj.yml/badge.svg)](https://github.com/4d/build4d-action/actions/workflows/buildprj.yml)

Take you 4D base and compile it.

Convert compilation errors as github annotations.

## Usage

Create workfile inside your repository with `.github/workflows/`, for instance `build.yml`, and put inside

```yaml
name: Build
on:
  push:
    paths:
      - '**.4dm'
  pull_request:
    paths:
      - '**.4dm'
  workflow_dispatch:

jobs:
  build:
    name: "Build"
    runs-on: windows-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v3
    - name: Build
      uses: 4d/build4d-action@main
```

### to build on macOS and window

use matrix

```yaml
name: build
on:
 push:
    paths:
      - '**.4dm'
  pull_request:
    paths:
      - '**.4dm'
  workflow_dispatch:

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
