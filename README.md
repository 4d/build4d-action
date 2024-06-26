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
      uses: actions/checkout@v4
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
      uses: actions/checkout@v4
    - name: Build
      uses: 4d/build4d-action@main
```

### action options

#### `project`

You could pass the path of the project to compile it, if the project is not inside the `Project` folder.

#### choosing 4d version

The options are the same found [tool4d-action project](https://github.com/4d/tool4d-action/blob/main/README.md#choose-the-tool4d-version)

#### compilations options

See documentation of `Compiler projet` 4d command for more information

- `targets`: x86_64_generic or/and arm64_macOS_lib (default: empty string, ie. do only check syntax)
  - support some shortcut: all (x86_64_generic & arm64_macOS_lib), current, available (on macOS x86_64_generic & arm64_macOS_lib, otherwise x86_64_generic)
- `type-inference`: all, locals or none (default: none)
- `generate-symbols`: true if needed (default: false)
- `generate-typing-methods`: reset or append (default: empty string)

#### reporting options

- `ignore-warnings`: do not display compilation warnings if set to true
- `fail-on-warning`: by default a warning do not make the task failed, if you want to be more strict you could set this option to true

#### more options

You could do more than build. For instance you could pack(create 4DZ), and archive result (into zip)

- `actions`: "build,pack,archive"

##### sign options

To sign add the action

- `actions`: "build,pack,sign,archive"

then you must specify the certificate name that you install in a previous step (using Github secret for instance)
- `sign-certificate`: name of the certificate, could be the full name or a part of it (for instance "Developer ID" for "Developer ID of MyFirm")
- `sign-files`: list of files paths relative to the base that must be signe too (for instance some binaries in resources). (pattern or folder are not supported)
- `entitlements-file`: if do not want to use default one provide a path for a custom entitlements file

```yaml
    - name: Build
      uses: 4d/build4d-action@main
      with:
        actions: "build,pack,sign,archive"
        sign-certificate: "Developer ID"
```

## Others

- Based on github action: https://github.com/4d/tool4d-action
- Example base: https://github.com/e-marchand/tool4d-action-test
