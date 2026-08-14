// This target intentionally declares no macros of its own.
//
// The `@PublicInit` macro is declared in the app sources
// (Nimb/Sources/Library/Macros.swift) and points directly at
// `#externalMacro(module: "MyMacroMacros", ...)`. This library target exists
// only as the product the Xcode targets link against: depending on it is what
// causes the MyMacroMacros compiler plugin to be built and passed to the
// compiler via -load-plugin-executable.
//
// Removing this target breaks `@PublicInit` expansion in every target.
