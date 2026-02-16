# Copyright (C) 2024 Toitware ApS.
# Use of this source code is governed by a Zero-Clause BSD license that can
# be found in the LICENSE file.

SOURCE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SHELL := bash
.SHELLFLAGS += -e

# Change to your configuration. See toit/toolchains for the available targets.
# Then run 'make init'.
IDF_TARGET := esp32c6

# Envelope variants.
VARIANT ?= esp32c6-standard
VARIANTS ?= esp32c6-standard esp32c6-large-partitions esp32c6-single-ota

# Set to false to avoid initializing submodules at every build.
INITIALIZE_SUBMODULES := true
# A semicolon-separated list of directories that contain components
#   and external libraries.
COMPONENTS := $(SOURCE_DIR)/components

# Constants that typically don't need to be changed.
BUILD_ROOT := $(SOURCE_DIR)/build-root
BUILD_PATH := $(SOURCE_DIR)/build
DIST_DIR := $(SOURCE_DIR)/dist
TOIT_ROOT := $(SOURCE_DIR)/toit
IDF_PATH := $(TOIT_ROOT)/third_party/esp-idf
IDF_PY := $(IDF_PATH)/tools/idf.py

all: envelope

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
	@$(MAKE) envelope VARIANT=$(VARIANT)

.PHONY: list-variants
list-variants:
	@printf "%s\n" $(VARIANTS)

.PHONY: envelope
envelope: initialize-submodules
	@if [[ ! -f "$(BUILD_ROOT)/sdkconfig.defaults" || ! -f "$(BUILD_ROOT)/partitions.csv" ]]; then \
	  echo "Run 'make init' first"; \
	  exit 1; \
	fi
	@if [[ ! -f "$(SOURCE_DIR)/variants/$(VARIANT)/partitions.csv" ]]; then \
	  echo "Unknown VARIANT: $(VARIANT)"; \
	  echo "Known variants:"; \
	  $(MAKE) list-variants; \
	  exit 1; \
	fi
	@mkdir -p "$(DIST_DIR)"
	@tmp_part=$$(mktemp); \
	  cp "$(BUILD_ROOT)/partitions.csv" "$$tmp_part"; \
	  cp "$(SOURCE_DIR)/variants/$(VARIANT)/partitions.csv" "$(BUILD_ROOT)/partitions.csv"; \
	  $(MAKE) -C "$(BUILD_ROOT)" \
	    COMPONENTS=$(COMPONENTS) \
	    BUILD_PATH=$(BUILD_PATH)/variants/$(VARIANT) \
	    BASE_BUILD_PATH=$(BUILD_PATH) \
	    TOIT_ROOT=$(TOIT_ROOT) \
	    IDF_TARGET=$(IDF_TARGET) \
	    IDF_PATH=$(IDF_PATH) \
	    IDF_PY=$(IDF_PY) \
	    esp32; \
	  status=$$?; \
	  if [[ $$status -eq 0 ]]; then \
	    cp "$(BUILD_PATH)/variants/$(VARIANT)/$(IDF_TARGET)/firmware.envelope" "$(DIST_DIR)/$(VARIANT).envelope"; \
	  fi; \
	  mv "$$tmp_part" "$(BUILD_ROOT)/partitions.csv"; \
	  exit $$status

.PHONY: envelopes
envelopes: initialize-submodules
	@for v in $(VARIANTS); do \
	  $(MAKE) envelope VARIANT=$$v; \
	done

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
