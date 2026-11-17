# Copyright (C) 2024 Toitware ApS.
# Use of this source code is governed by a Zero-Clause BSD license that can
# be found in the LICENSE file.

cmake_minimum_required(VERSION 3.5)

set(IDF_PATH "$ENV{IDF_PATH}" CACHE FILEPATH "Path to the ESP-IDF directory")
set(TOIT_SDK_DIR "$ENV{TOIT_SDK_DIR}" CACHE FILEPATH "Path to the Toit SDK directory")
set(TOIT_EXTRA_COMPONENTS "$ENV{TOIT_EXTRA_COMPONENTS}" CACHE FILEPATH "Path to Toit components directories")
set(TOIT_ROOT "$ENV{TOIT_ROOT}" CACHE PATH "Path to Toit sources")

list(APPEND EXTRA_COMPONENT_DIRS "${TOIT_ROOT}/toolchains/idf/components" ${TOIT_EXTRA_COMPONENTS})

include("${IDF_PATH}/tools/cmake/project.cmake")
project(toit)

include("local.cmake" OPTIONAL)

toit_postprocess()
