NAME := Nimb
BUILD_DIR := .build
NEOVIM_DIR := Third-Party/neovim
GENERATED_DIR := Nimb/Sources/generated
DERIVED_DATA_DIR := $(BUILD_DIR)/DerivedData
EXPORT_OPTIONS_PLIST := ExportOptions.plist
INSTALL_DIR := /Applications
SWIFTFORMAT := /opt/homebrew/bin/swiftformat

# CMake Configuration
export CMAKE_GENERATOR := Unix Makefiles
export CMAKE_BUILD_TYPE := Release
export CMAKE_EXTRA_FLAGS := -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0

# Targets
.PHONY: all test clean neovim generate format app install

# macOS App
app:
	xcodebuild archive -workspace Nimb.xcworkspace \
		-scheme Nimb -configuration Release -archivePath $(BUILD_DIR)/Nimb.xcarchive | xcbeautify; \
	xcodebuild -exportArchive -archivePath $(BUILD_DIR)/Nimb.xcarchive \
		-exportOptionsPlist $(EXPORT_OPTIONS_PLIST) -exportPath $(INSTALL_DIR) | xcbeautify

# Neovim
neovim: build_neovim_package
	@echo "Extracting Neovim package..."
	pushd $(NEOVIM_DIR)/build > /dev/null && tar -xvf nvim-macos-arm64.tar.gz && \
	popd > /dev/null && rm -rf $(NEOVIM_DIR)/.deps && \
	mkdir -p $(BUILD_DIR) && rm -rf $(BUILD_DIR)/package && \
	mv $(NEOVIM_DIR)/build/nvim-macos-arm64 $(BUILD_DIR)/package

build_neovim_package:
	@echo "Building Neovim package..."
	pushd $(NEOVIM_DIR) > /dev/null && \
		CMAKE_BUILD_TYPE=RelWithDebInfo make deps && \
		pushd build > /dev/null && \
			CMAKE_BUILD_TYPE=RelWithDebInfo make package && \
		popd > /dev/null && \
	popd > /dev/null

# Clean Neovim
clean_neovim:
	@echo "Cleaning Neovim build..."
	pushd $(NEOVIM_DIR) > /dev/null && \
		make clean && \
	popd > /dev/null

# Clean Build
clean: clean_neovim
	@echo "Cleaning build directory..."
	rm -rf $(BUILD_DIR)

# Format
format:
	@echo "Formatting Swift files..."
	$(SWIFTFORMAT) --config .swiftformat Nimb/ generate/ msgpack-inspector/ speed-tuner/

# Generate
generate:
	@echo "Generating Swift Neovim API code..."
	xcodebuild -workspace Nimb.xcworkspace -scheme generate -configuration Debug \
		-destination "platform=macOS,arch=arm64" -derivedDataPath $(DERIVED_DATA_DIR) | xcbeautify && \
		$(BUILD_DIR)/package/bin/nvim --api-info | $(DERIVED_DATA_DIR)/Build/Products/Debug/generate $(GENERATED_DIR)

# Install
install: neovim generate format app
