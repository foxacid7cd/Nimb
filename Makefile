NAME := Nimb
BUILD_DIR := .build
NEOVIM_DIR := Third-Party/neovim
SWIFTFORMAT := /opt/homebrew/bin/swiftformat
DERIVED_DATA_DIR := $(BUILD_DIR)/DerivedData

export CMAKE_GENERATOR := Unix Makefiles
export CMAKE_BUILD_TYPE := Release
export CMAKE_EXTRA_FLAGS := -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0

.PHONY: all test clean export_xcarchive neovim install

$(BUILD_DIR)/Nimb.xcarchive: generate
	xcodebuild archive -workspace Nimb.xcworkspace -scheme Nimb -configuration Release -archivePath $(BUILD_DIR)/Nimb.xcarchive | xcbeautify

export_xcarchive: $(BUILD_DIR)/Nimb.xcarchive
	xcodebuild -exportArchive -archivePath $(BUILD_DIR)/Nimb.xcarchive -exportOptionsPlist Scripts/exportOptions.plist -exportPath /Applications/ | xcbeautify

build_neovim_package:
	pushd $(NEOVIM_DIR) && make deps && \
		pushd build && make package && \
			popd && popd

extract_neovim_package:
	pushd $(NEOVIM_DIR)/build && tar -xvf nvim-macos-arm64.tar.gz && \
  	popd && mkdir -p $(BUILD_DIR) && rm -rf $(BUILD_DIR)/package && mv $(NEOVIM_DIR)/build/nvim-macos-arm64 $(BUILD_DIR)/package

neovim: build_neovim_package extract_neovim_package

clean_neovim:
	pushd $(NEOVIM_DIR) && make clean && popd

clean: clean_neovim
	rm -rf $(BUILD_DIR)

format:
	$(SWIFTFORMAT) --config .swiftformat Nimb/ generate/ Macros/ msgpack-inspector/ speed-tuner/

generate: neovim
	xcodebuild -workspace Nimb.xcworkspace -scheme generate -configuration Debug -destination "platform=macos,arch=arm64" -derivedDataPath $(DERIVED_DATA_DIR) | xcbeautify && \
		$(BUILD_DIR)/package/bin/nvim --api-info | $(DERIVED_DATA_DIR)/Build/Products/Debug/generate Nimb/Sources/generated

install: export_xcarchive format
