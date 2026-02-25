# Lightbug custom Toit envelopes

This repository creates custom [envelopes](https://docs.toit.io/tutorials/containers)
for [Toit](https://toitlang.org/) use with Lightbug devices, and is based on [this template repository](https://github.com/toitlang/template-custom-envelope).

## Releases

You can find released envelopes under the Github releases page: https://github.com/lightbug-io/toit-envelopes/releases

Tags should be release-centric (not Toit-version-centric), for example:

* `lb.YYYYMMDD-HHMM`
* `lb.YYYYMMDD-1` (if you prefer daily numbering)

Each release asset name includes both the variant and the Toit version label.

## Setup

### Prerequisites
* Make sure you have a complete build environment. See
  - https://github.com/toitlang/toit, and
  - https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/index.html
  - A good starting point is to run `install.sh` from the `toit/third_party/esp-idf` folder.

The [ci.yml](.github/workflows/ci.yml) file uses Toit's setup action to install all prerequisites on a GitHub runner.

This CI action will build artifacts on every push, as well as create release artifacts on every tag.

### Initial setup

* Duplicate this repository:

  Start by creating a fresh repository on GitHub. Then run the following
  commands, replacing `your-owner/your-repo` with the name of your repository:

  ``` shell
  git clone --bare https://github.com/toitlang/template-custom-envelope.git
  cd template-custom-envelope.git
  git push --mirror git@github.com:your-owner/your-repo.git
  cd ..
  rm -rf template-custom-envelope.git
  ```

  Also see [GitHub's instructions](https://docs.github.com/en/repositories/creating-and-managing-repositories/duplicating-a-repository).
  If you forked it, you can also detach the fork: https://support.github.com/request/fork

* Check out your new repository (again replacing `your-repo` with the name of your repository):

  ``` shell
  git clone git@github.com:your-owner/your-repo.git
  cd your-repo
  ```

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
* Change the `IDF_TARGET` variable in the Makefile to the name of your chip.
* Run `make init`. This will copy some of the Toit files, depending on the target, to your repository.

After initialization you should have the files `sdkconfig.defaults` and `partitions.csv` in the `build-root`
folder. Together with the `sdkconfig` file, which is created when building, these files should be
checked into your repository.

### Configuration
* Adjust or remove the C components in the `components` folder.
* Run `make menuconfig` to configure the build.
* Adjust the [ci.yml](.github/workflows/ci.yml) file to match your setup. Typically, you don't need
  to compile on Windows or macOS.

This repository supports per-variant overrides:

* `variants/<name>/partitions.csv` (optional) - partition table override for a variant.
* `variants/<name>/sdkconfig.defaults` (optional) - extra sdkconfig lines appended to the target defaults.
* `variants/<name>/idf_target` (optional) - ESP-IDF target for this variant (for example `esp32s3`).

### Build
This repository is set up to build multiple envelope variants.

Current variants include:

* `esp32c6-standard`
* `esp32c6-large-partitions`
* `esp32c6-single-ota`
* `esp32s3-no-spram` (ESP32-S3 variant with SPIRAM disabled to avoid SPIRAM attempts and pin usage)

* Build one envelope variant:

  ``` shell
  make init
  make envelope VARIANT=esp32s3-no-spram
  ```

  The resulting envelope is written to `dist/<variant>.envelope`.

* Build all variants:

  ``` shell
  make init
  make envelopes
  ```

  All resulting envelopes are written to `dist/*.envelope`.

* Build against a specific Toit ref (tag/branch/commit):

  ``` shell
  make init TOIT_REF=v2.0.0-alpha.190
  make envelope VARIANT=esp32c6-standard TOIT_REF=v2.0.0-alpha.190
  ```

  This updates the checked-out `toit` submodule to the requested ref for the build.

## Makefile targets
- `make` or `make all` - Build the default envelope variant.
- `make init` - Initialize after cloning. See the Setup section above.
- `make menuconfig` - Runs the ESP-IDF menuconfig tool in the build-root. Also creates the `sdkconfig.defaults` file.
- `make diff` - Show the differences between your configuration (sdkconfig and partitions.csv) and the default Toit configuration.
- `make clean` - Remove all build artifacts.
- `make envelope VARIANT=<name>` - Build one variant and write `dist/<name>.envelope`.
- `make envelopes` - Build all variants.
- `make list-variants` - Print the known variants.
