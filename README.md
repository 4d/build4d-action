# build4d-action

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
      uses: e-marchand/build4d-action@main
      with:
        project: "${{ github.workspace }}/Project/MyProject.4DProject"
```
