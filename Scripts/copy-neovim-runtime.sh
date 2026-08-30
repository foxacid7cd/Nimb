#!/bin/zsh
#
# Copies the Neovim build produced by `make neovim` into the app bundle.
#
# This replaces two build phases from the hand-maintained project: the
# "Copy nvim Executable" copy-files phase (dstSubfolderSpec 6, i.e.
# Contents/MacOS) and the inline "Copy Neovim Runtime" script. They are merged
# here because the nvim binary lives under .build/package, which does not exist
# at `tuist generate` time — a copy-files phase would silently resolve to
# nothing and ship an app with no Neovim in it. Failing loudly is better.

set -euo pipefail

PACKAGE_DIR="$PROJECT_DIR/.build/package"

if [[ ! -d "$PACKAGE_DIR" ]]; then
  >&2 echo "Fatal: $PACKAGE_DIR not found. Run 'make neovim' first."
  exit 1
fi

# nvim executable -> Nimb.app/Contents/MacOS/nvim
# Neovim.swift resolves it via Bundle.main.path(forAuxiliaryExecutable:).
install -m 0755 "$PACKAGE_DIR/bin/nvim" \
  "$TARGET_BUILD_DIR/$EXECUTABLE_FOLDER_PATH/nvim"

# runtime -> Nimb.app/Contents/Resources/nvim
DESTINATION_DIR="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Resources/nvim"
rm -rf "$DESTINATION_DIR"
mkdir -p "$DESTINATION_DIR"

RUNTIME_DIR="$DESTINATION_DIR/runtime"
mkdir -p "$RUNTIME_DIR"

cp -R "$PACKAGE_DIR/share/nvim/runtime/" "$RUNTIME_DIR"
cp -R "$PACKAGE_DIR/lib/nvim/" "$RUNTIME_DIR"
cp -R "$PROJECT_DIR/NeovimRuntime/src/nimb-gui" "$RUNTIME_DIR/lua"
cp "$PROJECT_DIR/NeovimRuntime/src/init.lua" "$DESTINATION_DIR"

# Xcode signs the app wrapper after every build phase, but never the Mach-O
# files copied here, and an unsigned one invalidates the bundle's signature.
IDENTITY="${EXPANDED_CODE_SIGN_IDENTITY_NAME:-${CODE_SIGN_IDENTITY:--}}"
codesign --force --timestamp=none --sign "$IDENTITY" \
  "$TARGET_BUILD_DIR/$EXECUTABLE_FOLDER_PATH/nvim"
find "$RUNTIME_DIR" -name '*.so' -exec \
  codesign --force --timestamp=none --sign "$IDENTITY" {} +
