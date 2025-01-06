# Lightbug custom Toit envelopes

This repository is used to create custom [envelopes](https://docs.toit.io/tutorials/containers)
for [Toit](https://toitlang.org/) specifically for Lightbug.

This repo was created from a [template](https://github.com/toitlang/template-custom-envelope) Zero-Clause BSD License Copyright (C) 2024 Toitware ApS.

## Setup

### Prerequisites
* Make sure you have a complete build environment. See
  - https://github.com/toitlang/toit, and
  - https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/index.html
  - A good starting point is to run `install.sh` from the `toit/third_party/esp-idf` folder.

* You may also need: `sudo apt install python3-venv ninja-build`

The [ci.yml](.github/workflows/ci.yml) file uses Toit's setup action to install all prerequisites
on a GitHub runner. You can use this as a reference for setting up your own environment.

### Initial setup

* Update the Toit submodule to match your needs.
  If you are using an installed [Jaguar](https://github.com/toitlang/jaguar), you
  should use the same SDK version as Jaguar. Use `jag version` to find the version.
  Otherwise, consider using the latest version.

  ``` shell
  pushd toit
  git checkout YOUR_VERSION
  git submodule update --init --recursive
  popd
  ```

* Change the license to your license.
* Change the `TARGET` variable in the Makefile to the name of your chip. By default it is set to `esp32`.
* Run `make init`. This will copy some of the Toit files, depending on the target, to your repository.

After initialization you should have the files `sdkconfig.defaults` and `partitions.csv` in the `build-root`
folder. Together with the `sdkconfig` file, which is created when building, these files should be
checked into your repository.

### Configuration
* Adjust or remove the C components in the `components` folder.
* Run `make menuconfig` to configure the build.
* Adjust the [ci.yml](.github/workflows/ci.yml) file to match your setup. Typically, you don't need
  to compile on Windows or macOS.

### Build
* Run `make` to build the envelope. It should end up with a `build/esp32/firmware.envelope`.

### Flash

```sh
jag flash build/esp32c3/firmware.envelope
```

## Adding container

You can add a container to an envelope...

Something like..

```sh
# Copy the envelope to a new file for modification
cp ./build/host/firmware.envelope ./build/esp32c-noconsole-container-nouartprint.envelope
cp ./build/host/firmware.envelope ./build/esp32c-noconsole-container-uartecho.envelope
# Build our containers
./build/host/sdk/bin/toit compile --snapshot -o lightbug-nouartprint.snapshot ./../toit/src/lb.toit
./build/host/sdk/bin/toit compile --snapshot -o uartecho.snapshot ./../toit/src/uartecho.toit
# Add containers to envelopes
./build/host/sdk/bin/toit tool firmware -e ./build/esp32c-noconsole-container-nouartprint.envelope container install lightbug lightbug-nouartprint.snapshot
./build/host/sdk/bin/toit tool firmware -e ./build/esp32c-noconsole-container-uartecho.envelope container install lightbug uartecho.snapshot
```


## Makefile targets
- `make` or `make all` - Build the envelope.
- `make init` - Initialize after cloning. See the Setup section above.
- `make menuconfig` - Runs the ESP-IDF menuconfig tool in the build-root. Also creates the `sdkconfig.defaults` file.
- `make diff` - Show the differences between your configuration (sdkconfig and partitions.csv) and the default Toit configuration.
- `make clean` - Remove all build artifacts.
