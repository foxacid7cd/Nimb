NAME            := Nimb
BUILD_DIR       := $(CURDIR)/.build
PACKAGE_DIR     := $(BUILD_DIR)/package
DERIVED_DATA    := $(BUILD_DIR)/DerivedData
NEOVIM_DIR      := $(CURDIR)/Third-Party/neovim
GENERATED_DIR   := $(CURDIR)/Sources/NimbNeovim/Generated
EXPORT_OPTIONS  := $(CURDIR)/ExportOptions.plist
INSTALL_DIR     := /Applications

MISE            := mise
TUIST           := $(MISE) exec -- tuist
SWIFTFORMAT     := $(MISE) exec -- swiftformat

# CMake configuration for the Neovim submodule build.
export CMAKE_GENERATOR   := Ninja
export CMAKE_BUILD_TYPE  := Release
export CMAKE_EXTRA_FLAGS := -DCMAKE_OSX_DEPLOYMENT_TARGET=15.6

.PHONY: all bootstrap project neovim generate format app install clean clean-neovim

all: install

## Install the pinned toolchain (tuist, swiftformat).
bootstrap:
	$(MISE) install

## Generate Nimb.xcodeproj / Nimb.xcworkspace from Project.swift.
project: bootstrap
	$(TUIST) generate --no-open

## Build Neovim and install it into .build/package.
neovim:
	@echo "Building Neovim..."
	rm -rf "$(PACKAGE_DIR)"
	mkdir -p "$(PACKAGE_DIR)"
	$(MAKE) -C "$(NEOVIM_DIR)" CMAKE_INSTALL_PREFIX="$(PACKAGE_DIR)" install

## Regenerate the Swift Neovim API bindings from `nvim --api-info`.
generate: project
	@echo "Generating Swift Neovim API code..."
	@test -x "$(PACKAGE_DIR)/bin/nvim" || { echo "Run 'make neovim' first."; exit 1; }
	mkdir -p "$(GENERATED_DIR)"
	xcodebuild -workspace "$(NAME).xcworkspace" -scheme generate \
		-configuration Debug -destination "platform=macOS,arch=arm64" \
		-derivedDataPath "$(DERIVED_DATA)" build
	"$(PACKAGE_DIR)/bin/nvim" --api-info | \
		"$(DERIVED_DATA)/Build/Products/Debug/generate" "$(GENERATED_DIR)"

format:
	@echo "Formatting Swift files..."
	@# Tuist manifests are deliberately excluded: the acronyms rule rewrites
	@# API labels such as bundleId: into bundleID:, which does not compile.
	$(SWIFTFORMAT) --config .swiftformat \
		Nimb/ Sources/ generate/ msgpack-inspector/ speed-tuner/

app: project
	xcodebuild archive -workspace "$(NAME).xcworkspace" -scheme "$(NAME)" \
		-configuration Release -archivePath "$(BUILD_DIR)/$(NAME).xcarchive"
	xcodebuild -exportArchive -archivePath "$(BUILD_DIR)/$(NAME).xcarchive" \
		-exportOptionsPlist "$(EXPORT_OPTIONS)" -exportPath "$(INSTALL_DIR)"

install: neovim generate format app

clean-neovim:
	$(MAKE) -C "$(NEOVIM_DIR)" distclean

clean: clean-neovim
	$(TUIST) clean
	rm -rf "$(BUILD_DIR)" Derived "$(NAME).xcodeproj" "$(NAME).xcworkspace"
