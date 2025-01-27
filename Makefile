NAME := Nimb
BUILD_DIR := .build
NEOVIM_DIR := Third-Party/neovim
GENERATED_DIR := Nimb/Sources/generated
DERIVED_DATA_DIR := $(BUILD_DIR)/DerivedData
EXPORT_OPTIONS_PLIST := ExportOptions.plist
INSTALL_DIR := /Applications
SWIFTFORMAT := /opt/homebrew/bin/swiftformat

# CMake Configuration
export CMAKE_GENERATOR := Ninja
export CMAKE_BUILD_TYPE := Release
export CMAKE_EXTRA_FLAGS := -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0

# Targets
.PHONY: all test clean neovim generate format app install

# macOS App
app:
	xcodebuild archive -workspace Nimb.xcworkspace \
		-scheme Nimb -configuration Release -archivePath $(BUILD_DIR)/Nimb.xcarchive && \
	xcodebuild -exportArchive -archivePath $(BUILD_DIR)/Nimb.xcarchive \
		-exportOptionsPlist $(EXPORT_OPTIONS_PLIST) -exportPath $(INSTALL_DIR)

# Neovim
neovim: 
	@echo "Building Neovim..."
	mkdir -p $(BUILD_DIR) && rm -rf $(BUILD_DIR)/package && mkdir -p $(BUILD_DIR)/package && \
	pushd $(NEOVIM_DIR) > /dev/null && \
		make CMAKE_INSTALL_PREFIX=$PWD/../../../.build/package install && \
	popd > /dev/null

# Clean Neovim
clean_neovim:
	@echo "Cleaning Neovim build..."
	pushd $(NEOVIM_DIR) > /dev/null && \
		make distclean && \
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
		-destination "platform=macOS,arch=arm64" -derivedDataPath $(DERIVED_DATA_DIR) && \
		$(BUILD_DIR)/package/bin/nvim --api-info | $(DERIVED_DATA_DIR)/Build/Products/Debug/generate $(GENERATED_DIR)

# Install
install: neovim generate format app
