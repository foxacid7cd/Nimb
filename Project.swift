import ProjectDescription

func makeTarget(name: String, product: Product, dependencies: [TargetDependency] = []) -> Target {
  return .init(
    name: name,
    platform: .macOS,
    product: product,
    bundleId: "foxacid7cd.\(name)",
    deploymentTarget: .macOS(targetVersion: "12.3"),
    infoPlist: .extendingDefault(with: [:]),
    sources: ["Targets/\(name)/Sources/**"],
    resources: product == .app ? ["Targets/\(name)/Resources/**"] : [],
    dependencies: dependencies,
    settings: .settings(
      base: [:],
      debug: [:],
      release: [:],
      defaultSettings: .recommended()
    )
  )
}

let project = Project(
  name: "Nims",
  organizationName: "foxacid7cd",
  options: .options(
    automaticSchemesOptions: .enabled(),
    textSettings: .textSettings(
      usesTabs: false,
      indentWidth: 2,
      tabWidth: 2,
      wrapsLines: true
    )
  ),
  targets: [
    makeTarget(
      name: "Nims",
      product: .app,
      dependencies: [
        .target(name: "Library"),
        .target(name: "Procedures")
      ]
    ),
    makeTarget(
      name: "neogen",
      product: .commandLineTool,
      dependencies: [
        .target(name: "Library"),
        .target(name: "Procedures"),
        .external(name: "Stencil"),
        .external(name: "ArgumentParser")
      ]
    ),
    makeTarget(
      name: "Procedures",
      product: .staticLibrary,
      dependencies: [
        .target(name: "Library"),
        .target(name: "Conversations")
      ]
    ),
    makeTarget(
      name: "Conversations",
      product: .staticLibrary,
      dependencies: [
        .target(name: "Library"),
        .external(name: "MessagePack")
      ]
    ),
    makeTarget(
      name: "Library",
      product: .staticLibrary
    )
  ],
  additionalFiles: ["Templates/**"]
)
