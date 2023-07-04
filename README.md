# build4d-action

[![build](https://github.com/4d/build4d-action/actions/workflows/build.yml/badge.svg)](https://github.com/4d/build4d-action/actions/workflows/build.yml)
[![buildprj](https://github.com/4d/build4d-action/actions/workflows/buildprj.yml/badge.svg)](https://github.com/4d/build4d-action/actions/workflows/buildprj.yml)

Take your 4D project and compile it.

Convert compilation errors as github annotations.

## Usage

Create workflow file inside your repository inside `.github/workflows/`, for instance name `build.yml`, and put inside the following content

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

At each 4dm modification the build check syntax will be launched. See "Actions" tabs of your project.

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

### action options

#### `project`

you could pass the path of the project to compile if the project is not inside `Project` folder

#### compilations options

see documentation of `Compiler projet` 4d command for more information

- `targets`: x86_64_generic or/and arm64_macOS_lib (default: empty string, ie. do only check syntax)
- `type-inference`: all, locals or none (default: none)
- `generate-symbols`: true if needed (default: false)
- `generate-typing-methods`: reset or append (default: empty string)

#### reporting options

- `ignore-warnings`: do not display compilation error warnings if set to true
- `fail-on-warning`: by default a warning do not make the task failed, if you want to be more strict you could set to true this topion

#### choose 4d version

The options are the same than tool4d-action: https://github.com/4d/tool4d-action#choose-tool4d-version-v1

## Others

- Based on github action: https://github.com/4d/tool4d-action
- Example base: https://github.com/e-marchand/tool4d-action-test
