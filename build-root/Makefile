# Copyright (C) 2024 Toitware ApS.
# Use of this source code is governed by a Zero-Clause BSD license that can
# be found in the LICENSE file.

SOURCE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SHELL := bash
.SHELLFLAGS += -e

# All these variable should be set when calling this Makefile.
# The top-level Makefile does this.
IDF_TARGET :=
COMPONENTS :=
BUILD_PATH :=
BASE_BUILD_PATH :=
TOIT_ROOT :=
IDF_PATH :=
IDF_PY :=

ifndef BUILD_PATH
$(error BUILD_PATH is not set)
endif
ifndef IDF_TARGET
$(error IDF_TARGET is not set)
endif

BASE_BUILD_PATH ?= $(BUILD_PATH)
IDF_BUILD_PATH := $(BUILD_PATH)/$(IDF_TARGET)
HOST_BUILD_PATH := $(BASE_BUILD_PATH)/host
SDK_PATH := $(HOST_BUILD_PATH)/sdk

ifeq ($(OS),Windows_NT)
	EXE_SUFFIX=.exe
else
	EXE_SUFFIX=
endif

define call-cmake
	@cmake -E env \
		"IDF_PATH=$(IDF_PATH)" \
		"IDF_TARGET=$(IDF_TARGET)" \
		"IDF_CCACHE_ENABLE=1" \
		"TOIT_EXTRA_COMPONENTS=$(COMPONENTS)" \
		"TOIT_SDK_DIR=$(SDK_PATH)" \
		python $(IDF_PY) -B "$(IDF_BUILD_PATH)" $(1)
endef

.PHONY: all
all: esp32

.PHONY: check-env
check-env:
	@$(MAKE) -C "$(TOIT_ROOT)" check-env
	@$(MAKE) -C "$(TOIT_ROOT)" check-esp32-env

.PHONY: check-windows
check-windows:
	@if [ "$(OS)" = "Windows_NT" ]; then \
		echo "==============================================================="; \
		echo "Please run in a powershell:"; \
		if [ "$(shell command -v xtensa-esp32-elf-g++)" = "" ]; then \
			echo '$(IDF_PATH)/export.ps1'; \
		fi; \
		echo 'cmake -E env "IDF_PATH=$(IDF_PATH)" "IDF_TARGET=$(IDF_TARGET)" "IDF_CCACHE_ENABLE=1" "TOIT_EXTRA_COMPONENTS=$(COMPONENTS)" "TOIT_SDK_DIR=$(SDK_PATH)" python $(IDF_PY) -B "$(IDF_BUILD_PATH)" -C "$(SOURCE_DIR)" build'; \
		echo "==============================================================="; \
		exit 1; \
	fi

.PHONY: esp32
esp32: $(SDK_PATH)/bin/toit$(EXE_SUFFIX) check-windows
	@if [ "$(shell command -v xtensa-esp32-elf-g++)" = "" ]; then \
		source '$(IDF_PATH)/export.sh'; \
	fi; \
	$(MAKE) esp32-no-env

.PHONY: esp32-no-env
esp32-no-env: check-env check-windows
	@$(call call-cmake,build)

.PHONY: build-host
build-host:
	@# Note that the 'host' is automatically added.
	@cmake -E env \
		"EXTERNAL_TOIT_LIB_DIRS=$(COMPONENTS)" \
		$(MAKE) -C "$(TOIT_ROOT)" BUILD=$(BASE_BUILD_PATH)

$(SDK_PATH)/bin/toit$(EXE_SUFFIX): build-host

.PHONY: menuconfig
menuconfig:
	@if [ "$(shell command -v xtensa-esp32-elf-g++)" = "" ]; then source '$(IDF_PATH)/export.sh'; fi; \
	$(MAKE) menuconfig-no-env

.PHONY: menuconfig-no-env
menuconfig-no-env: check-env
	@$(call call-cmake,menuconfig)
	@$(call call-cmake,save-defconfig)

.PHONY: clean
clean:
	@rm -rf "$(BUILD_PATH)"
