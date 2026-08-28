NAME            := Nimb
BUILD_DIR       := $(CURDIR)/.build
PACKAGE_DIR     := $(BUILD_DIR)/package
DERIVED_DATA    := $(BUILD_DIR)/DerivedData
NEOVIM_DIR      := $(CURDIR)/Third-Party/neovim
GENERATED_DIR   := $(CURDIR)/Sources/NimbNeovim/Generated
EXPORT_OPTIONS  := $(CURDIR)/ExportOptions.plist
INSTALL_DIR     := /Applications
ARCHIVE         := $(BUILD_DIR)/$(NAME).xcarchive
EXPORT_DIR      := $(BUILD_DIR)/export
RELEASE_APP     := $(DERIVED_DATA)/Build/Products/Release/$(NAME).app
NVIM_BIN        := $(PACKAGE_DIR)/bin/nvim
PROJECT_STAMP   := $(BUILD_DIR)/.project.stamp
GENERATE_STAMP  := $(BUILD_DIR)/.generate.stamp
TUIST_MANIFESTS := Project.swift Tuist.swift \
                   $(wildcard Tuist/ProjectDescriptionHelpers/*.swift)
GENERATOR_SRCS  := $(wildcard generate/*.swift)

MISE            := mise
TUIST           := $(MISE) exec -- tuist
SWIFTFORMAT     := $(MISE) exec -- swiftformat

# CMake configuration for the Neovim submodule build.
export CMAKE_GENERATOR   := Ninja
export CMAKE_BUILD_TYPE  := Release
export CMAKE_EXTRA_FLAGS := -DCMAKE_OSX_DEPLOYMENT_TARGET=15.6

.PHONY: all bootstrap project neovim generate format app archive install clean \
        clean-neovim

all: install

## Install the pinned toolchain (tuist, swiftformat).
bootstrap:
	$(MISE) install

## Generate Nimb.xcodeproj / Nimb.xcworkspace from Project.swift.
project: bootstrap $(PROJECT_STAMP)

$(PROJECT_STAMP): $(TUIST_MANIFESTS)
	$(TUIST) generate --no-open
	@mkdir -p "$(BUILD_DIR)"
	@touch $@

## Build Neovim and install it into .build/package.
neovim: $(NVIM_BIN)

# Not cleaned first: rebuilding Neovim is the longest step by far, and its own
# build system tracks what changed. `make clean-neovim` forces it.
$(NVIM_BIN):
	@echo "Building Neovim..."
	mkdir -p "$(PACKAGE_DIR)"
	$(MAKE) -C "$(NEOVIM_DIR)" CMAKE_INSTALL_PREFIX="$(PACKAGE_DIR)" install

## Regenerate the Swift Neovim API bindings from `nvim --api-info`.
generate: project $(GENERATE_STAMP)

# The bindings depend on the Neovim binary they are read out of and on the
# generator itself, so an unchanged pair regenerates nothing.
$(GENERATE_STAMP): $(NVIM_BIN) $(GENERATOR_SRCS) | $(PROJECT_STAMP)
	@echo "Generating Swift Neovim API code..."
	mkdir -p "$(GENERATED_DIR)"
	xcodebuild -workspace "$(NAME).xcworkspace" -scheme generate \
		-configuration Debug -destination "platform=macOS,arch=arm64" \
		-derivedDataPath "$(DERIVED_DATA)" build
	"$(NVIM_BIN)" --api-info | \
		"$(DERIVED_DATA)/Build/Products/Debug/generate" "$(GENERATED_DIR)"
	@mkdir -p "$(BUILD_DIR)"
	@touch $@

format:
	@echo "Formatting Swift files..."
	@# Tuist manifests are deliberately excluded: the acronyms rule rewrites
	@# API labels such as bundleId: into bundleID:, which does not compile.
	$(SWIFTFORMAT) --config .swiftformat Nimb/ Sources/ generate/

## Build Release and install it into /Applications.
#
# A plain build into persistent derived data rather than archive-and-export:
# the archive action rebuilds every target every time, where this reuses what
# the last build compiled. The exported app was adhoc signed exactly as this
# one is, so nothing is lost by copying the product straight across.
app: project
	xcodebuild build -workspace "$(NAME).xcworkspace" -scheme "$(NAME)" \
		-configuration Release -destination "platform=macOS,arch=arm64" \
		-derivedDataPath "$(DERIVED_DATA)"
	rm -rf "$(INSTALL_DIR)/$(NAME).app"
	ditto "$(RELEASE_APP)" "$(INSTALL_DIR)/$(NAME).app"

## Universal archive, exported to .build/export, for distributing.
archive: project
	xcodebuild archive -workspace "$(NAME).xcworkspace" -scheme "$(NAME)" \
		-configuration Release -archivePath "$(ARCHIVE)"
	rm -rf "$(EXPORT_DIR)"
	xcodebuild -exportArchive -archivePath "$(ARCHIVE)" \
		-exportOptionsPlist "$(EXPORT_OPTIONS)" -exportPath "$(EXPORT_DIR)"

install: neovim generate format app

clean-neovim:
	$(MAKE) -C "$(NEOVIM_DIR)" distclean

clean: clean-neovim
	$(TUIST) clean
	rm -rf "$(BUILD_DIR)" Derived "$(NAME).xcodeproj" "$(NAME).xcworkspace"
