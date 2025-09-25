# Copyright (C) 2024 Toitware ApS.
# Use of this source code is governed by a Zero-Clause BSD license that can
# be found in the LICENSE file.

SOURCE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SHELL := bash
.SHELLFLAGS += -e

# Change to your configuration. See toit/toolchains for the available targets.
# Then run 'make init'.
IDF_TARGET ?= esp32

# Set to false to avoid initializing submodules at every build.
INITIALIZE_SUBMODULES := true
# A semicolon-separated list of directories that contain components
#   and external libraries.
COMPONENTS := $(SOURCE_DIR)/components

# Constants that typically don't need to be changed.
BUILD_ROOT := $(SOURCE_DIR)/build-root
BUILD_PATH := $(SOURCE_DIR)/build
TOIT_ROOT := $(SOURCE_DIR)/toit
IDF_PATH := $(TOIT_ROOT)/third_party/esp-idf
IDF_PY := $(IDF_PATH)/tools/idf.py

all: esp32

define toit-make
	@$(MAKE) -C "$(BUILD_ROOT)" \
		COMPONENTS=$(COMPONENTS) \
		BUILD_PATH=$(BUILD_PATH) \
		TOIT_ROOT=$(TOIT_ROOT) \
		IDF_TARGET=$(IDF_TARGET) \
		IDF_PATH=$(IDF_PATH) \
		IDF_PY=$(IDF_PY) \
		$(1)
endef

.PHONY: initialize-submodules
initialize-submodules:
	@if [[ "$(INITIALIZE_SUBMODULES)" == "true" ]]; then \
	  echo "Initializing submodules"; \
		pushd toit && git submodule update --init --recursive && popd; \
	fi

.PHONY: host
host: initialize-submodules
	@$(call toit-make,build-host)

.PHONY: build-host
build-host: host

.PHONY: esp32
esp32: initialize-submodules
	@$(MAKE) idf-prepare

	@if [ -f $(BUILD_ROOT)/sdkconfig ]; then \
		current_target=$$(grep -E "^CONFIG_IDF_TARGET_" $(BUILD_ROOT)/sdkconfig | sed -n 's/CONFIG_IDF_TARGET_\([^=]*\)=y/\1/p' | tr '[:upper:]' '[:lower:]' || true); \
		if [ -n "$$current_target" ] && [ "$$current_target" != "$(IDF_TARGET)" ]; then \
			echo "Existing sdkconfig is for target '$$current_target' but IDF_TARGET is '$(IDF_TARGET)'. Removing stale sdkconfig so a fresh one will be created."; \
			rm -f $(BUILD_ROOT)/sdkconfig; \
		fi; \
	fi
	@if [[ ! -f $(BUILD_ROOT)/sdkconfig.defaults ]]; then \
	  echo "Run 'make init' first"; \
		exit 1; \
	fi
	@$(call toit-make,esp32)

.PHONY: idf-prepare
idf-prepare:
	@echo "Preparing ESP-IDF for target '$(IDF_TARGET)'"
	@echo "Checking ESP-IDF installation for target '$(IDF_TARGET)' (python env + toolchain)"
	@python_env_installed=false; \
	if ls "$$HOME/.espressif/python_env"/idf* >/dev/null 2>&1; then python_env_installed=true; fi; \
	toolchain_installed=false; \
	if [ -d "$$HOME/.espressif/tools" ] && [ -n "$$(ls -A "$$HOME/.espressif/tools" 2>/dev/null)" ]; then \
		if [ -d "$$HOME/.espressif/tools/xtensa-esp-elf" ] || [ -d "$$HOME/.espressif/tools/riscv32-esp-elf" ]; then \
			toolchain_installed=true; \
		fi; \
	fi; \
	if [ "$$python_env_installed" = true ] && [ "$$toolchain_installed" = true ]; then \
		echo "ESP-IDF appears installed (python env + toolchain present); skipping install.sh"; \
	else \
		echo "Installing ESP-IDF tools for target '$(IDF_TARGET)' (this may take a while)"; \
		( cd "$(IDF_PATH)" && ./install.sh $(IDF_TARGET) ) || true; \
	fi

	@echo "Setting ESP-IDF target to '$(IDF_TARGET)'"
	@bash -lc 'if [ -f "$(IDF_PATH)/export.sh" ]; then . "$(IDF_PATH)/export.sh"; fi; cd "$(BUILD_ROOT)" && "$(IDF_PY)" set-target $(IDF_TARGET)' || true

.PHONY: menuconfig
menuconfig: initialize-submodules
	@$(call toit-make,menuconfig)

.PHONY: clean
clean:
	@$(call toit-make,clean)

.PHONY: init
init: $(BUILD_ROOT)/sdkconfig.defaults $(BUILD_ROOT)/partitions.csv

$(BUILD_ROOT)/sdkconfig.defaults: initialize-submodules
	@cp $(TOIT_ROOT)/toolchains/$(IDF_TARGET)/sdkconfig.defaults $@

$(BUILD_ROOT)/partitions.csv: initialize-submodules
	@cp $(TOIT_ROOT)/toolchains/$(IDF_TARGET)/partitions.csv $@

.PHONY: diff
diff:
	@diff -U0 --color $(TOIT_ROOT)/toolchains/$(IDF_TARGET)/sdkconfig.defaults $(BUILD_ROOT)/sdkconfig.defaults || true
	@diff -U0 --color $(TOIT_ROOT)/toolchains/$(IDF_TARGET)/partitions.csv $(BUILD_ROOT)/partitions.csv || true
