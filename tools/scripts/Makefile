# Copyright 2017 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

MAKEFLAGS += --warn-undefined-variables --no-print-directory
SHELL := /bin/bash

.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

FUCHSIA_DIR ?= $(shell jiri -show-root)
ROOT ?= $(shell pwd)
PROJECT := $(subst $(FUCHSIA_DIR)/,,$(ROOT))
SCRIPTS_DIR ?= $(realpath $(FUCHSIA_DIR)/topaz/tools/scripts)
TOOLS_ROOT := $(realpath $(SCRIPTS_DIR)/..)
FLUTTER_ROOT := $(FUCHSIA_DIR)/third_party/dart-pkg/git/flutter
FLUTTER_BIN := $(FLUTTER_ROOT)/bin
DART_BIN := $(FLUTTER_BIN)/cache/dart-sdk/bin

FLUTTER := $(FLUTTER_BIN)/flutter
DART := $(DART_BIN)/dart
PUB := $(DART_BIN)/pub

IGNORED_DIRS := _book generated infra node_modules testdata ios .pub
IGNORE_FLAGS := $(shell echo $(addprefix '! -wholename "*/',$(addsuffix '/*"',$(IGNORED_DIRS))))
SFIND := find $(ROOT) $(IGNORE_FLAGS)

DART_SOURCES := $(shell $(SFIND) -name "*.dart")

DART_PACKAGES := $(realpath $(shell $(SFIND) -name "pubspec.yaml" -exec dirname {} \;))
DART_TOOLS_PACKAGES := $(realpath $(shell find $(TOOLS_ROOT) $(IGNORE_FLAGS) -name "pubspec.yaml" -exec dirname {} \;))
# find all dart packages defined in BUILD.gn
DART_GN_PACKAGES := $(realpath $(shell grep -Rwl . --include="*.gn" -e "^\(flutter_app\|dart_library\|dart_app\)" | xargs -n1 dirname | sort -u))
DART_ALL_PACKAGES := $(sort $(DART_PACKAGES) $(DART_TOOLS_PACKAGES) $(DART_GN_PACKAGES))

GN_SOURCES := $(shell $(SFIND) -name "*.gn")

SOURCES := $(shell $(SFIND) \
	\( -name "*.dart" \
	-o -name "*.py" \
	-o -name "*.fidl" \
	-o -name "*.gn" \
	-o -name "*.go" \
	-o -name "*.sh" \
	-o -name "*.yaml" \))

makefiles := $(foreach file, $(MAKEFILE_LIST), $(realpath $(file)))

PATH := $(FLUTTER_BIN):$(DART_BIN):$(FUCHSIA_DIR)/buildtools:$(FUCHSIA_DIR)/scripts:$(PATH)

################################################################################
## Fuchsia build / LUCI bot related flags

DEFAULT_MODULE ?= topaz/packages/default
MINIMAL_MODULE ?= topaz/packages/mods

# Specify GOMA=1 to force use goma, GOMA=0 to force not use goma.
# Auto-detect if not specified.
FX_SET_FLAGS :=
GOMA ?=
ifeq ($(GOMA),1)
	FX_SET_FLAGS += --goma
endif
ifeq ($(GOMA),0)
	FX_SET_FLAGS += --no-goma
endif

GOMA_DIR ?=
ifneq ($(strip $(GOMA_DIR)),)
	FX_SET_FLAGS += --goma-dir $(GOMA_DIR)
endif

# If NO_ENSURE_GOMA=1 then we tell fx not to run the goma script directly.
NO_ENSURE_GOMA ?=
ifeq ($(NO_ENSURE_GOMA),1)
	FX_SET_FLAGS += --no-ensure-goma
endif

# If MINIMAL=1 then we perform a minimal build of only the "modules" package and
# its dependencies.
MINIMAL ?=
ifeq ($(MINIMAL),1)
	FX_SET_FLAGS += --packages $(MINIMAL_MODULE)
else
	FX_SET_FLAGS += --packages $(DEFAULT_MODULE)
endif

# Respect the fuchsia build variant if already set by fset command externally.
# Otherwise, default to debug build.
FUCHSIA_VARIANT ?= debug
ifeq ($(FUCHSIA_VARIANT),release)
	FX_SET_FLAGS += --release
endif

BUILD_FLAGS := $(FX_SET_FLAGS)
FUCHSIA_GEN_TARGET ?= x64

################################################################################


.PHONY: all
all: build

.PHONY: init
init: ## Set path to pick up deps with: eval $(make init)
	@echo "export PATH=${PATH}"

.PHONY: build
build: ## Build Fuchsia with project.
	@FUCHSIA_DIR=$(FUCHSIA_DIR) \
		MAKEFLAGS="$(filter-out --warn-undefined-variables,$(MAKEFLAGS))" \
		$(SCRIPTS_DIR)/build.sh $(BUILD_FLAGS)

.PHONY: clean
clean: dart-clean ## Clean build artifacts from this project.

.PHONY: fmt
fmt: dart-fmt gn-fmt ## Format the code in this project.

.PHONY: test
test: dart-test ## Run the tests in this project.

.PHONY: coverage
coverage: dart-coverage ## Show coverage for this project.

.PHONY: presubmit
presubmit: build lint test ## Run the presubmit tests for this project.

.PHONY: presubmit-cq
presubmit-cq: presubmit

.PHONY: lint
lint: copyright-check dart-lint dart-fmt-check gn-fmt-check ## Lint the code.

%/.packages: %/pubspec.yaml
	@cd $* && $(FLUTTER) packages get

.PHONY: $(DART_BIN)
$(DART_BIN):
	@$(FLUTTER) precache

.PHONY: dart-clean
dart-clean:
	@# Remove all build artifacts, including the coverage information.
	@# Also, if there is a pubspec.lock file that is not tracked by git, remove
	@# it as well.
	@for pkg in $(DART_ALL_PACKAGES); do \
		pushd $${pkg} > /dev/null; \
		rm -rf .packages packages .pub build coverage; \
		git ls-files pubspec.lock --error-unmatch &> /dev/null; \
		if [ $$? -ne 0 ]; then \
			rm -f pubspec.lock; \
		fi; \
		popd > /dev/null; \
	done
	@rm -rf coverage

.PHONY: dart-lint
dart-lint: build
	@$(FUCHSIA_DIR)/scripts/run-dart-action.py analyze \
			--out=$$(fx get-build-dir) \
			--tree=//$(PROJECT)/* \
			--verbose \
			--lints --fatal-lints --fatal-warnings --fatal-hints

.PHONY: dart-fmt
dart-fmt: $(DART_BIN) $(TOOLS_ROOT)/dartfmt_extras/.packages
	@dartfmt -w $(DART_SOURCES)
	@cd $(TOOLS_ROOT)/dartfmt_extras; \
	FLUTTER_ROOT=$(FLUTTER_ROOT) $(PUB) run bin/main.dart fix / $(DART_SOURCES)

.PHONY: dart-fmt-check
dart-fmt-check: $(DART_BIN) $(TOOLS_ROOT)/dartfmt_extras/.packages
	@dartfmt --dry-run --set-exit-if-changed $(DART_SOURCES); \
	error=$$?; \
	cd $(TOOLS_ROOT)/dartfmt_extras; \
	FLUTTER_ROOT=$(FLUTTER_ROOT) $(PUB) run bin/main.dart check / $(DART_SOURCES); \
	if [ $$? -ne 0 -o $$error -ne 0 ] ; then \
		echo; \
		echo "The above dart files have formatting issues."; \
		echo "Run \"make fmt\" to fix the formatting."; \
		echo; \
		exit 1; \
	fi

.PHONY: dart-test
dart-test: build
	@$(FUCHSIA_DIR)/scripts/run-dart-action.py test \
			--out=$$(fx get-build-dir) \
			--tree=//$(PROJECT)/* \
			--verbose

.PHONY: dart-coverage
dart-coverage: $(DART_BIN)
	@$(SCRIPTS_DIR)/run_dart_tests.py --coverage
	@$(SCRIPTS_DIR)/merge_coverage.sh
	@$(DART) $(SCRIPTS_DIR)/report_coverage.dart coverage/lcov.info
	@## Remove the .packages files to sanitize the Atom dart analysis.
	@rm -f $(addsuffix "/.packages",$(DART_GN_PACKAGES))

.PHONY: copyright-check
copyright-check: ## Check source files for missing copyright.
	@$(SCRIPTS_DIR)/copyright-check.sh $(SOURCES)

.PHONY: gn-fmt
gn-fmt:
	@for src in $(GN_SOURCES); do \
		gn format $$src; \
	done

.PHONY: gn-fmt-check
gn-fmt-check:
	@export GN_FORMAT_ERROR=false; \
	for src in $(GN_SOURCES); do \
		if ! $$(gn format --dry-run $$src); then \
			export GN_FORMAT_ERROR=true; \
			echo "Formatting issues found in: '$${src}'"; \
		fi; \
	done; \
	if [ "$${GN_FORMAT_ERROR}" = true ]; then \
		echo; \
		echo "Run \"make fmt\" to fix the formatting."; \
		exit 1; \
	fi

.PHONY: help
help: ## Displays this help message.
	@for file in $(makefiles); do \
		grep -E '^[a-zA-Z_-]+:.*?## .*$$' $${file} | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'; \
	done
