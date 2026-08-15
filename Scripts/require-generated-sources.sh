#!/bin/zsh
#
# The Neovim API bindings are produced by `make generate` and are not checked
# in. Without them the module fails with hundreds of "cannot find type
# 'UIEvent'" errors, which is a confusing way to learn the bootstrap was
# skipped. Fail with one clear line instead.

set -euo pipefail

if [[ ! -f "$SRCROOT/Sources/NimbNeovim/Generated/APIFunctions.swift" ]]; then
  >&2 echo "error: Neovim API bindings are missing. Run 'make neovim && make generate' first."
  exit 1
fi
