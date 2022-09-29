import ProjectDescription

func createTarget(name: String, product: Product, dependencies: [TargetDependency] = []) -> Target {
  return .init(name: name, platform: .macOS, product: product, bundleId: "foxacid7cd.\(name)", deploymentTarget: .macOS(targetVersion: "12.3"), infoPlist: .extendingDefault(with: [:]), sources: ["Targets/\(name)/Sources/**"], resources: ["Targets/\(name)/Resources/**"], dependencies: dependencies, settings: .settings(base: [:], debug: [:], release: [:], defaultSettings: .recommended()))
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
    createTarget(
      name: "Nims",
      product: .app,
      dependencies: [
        .target(name: "Procedures")
      ]
    ),
    createTarget(
      name: "neogen",
      product: .commandLineTool,
      dependencies: [
        .target(name: "Procedures"),
        .external(name: "Stencil"),
        .external(name: "ArgumentParser"),
      ]
    ),
    createTarget(
      name: "Procedures",
      product: .staticLibrary,
      dependencies: [
        .target(name: "Conversations")
      ]
    ),
    createTarget(
      name: "Conversations",
      product: .staticLibrary,
      dependencies: [
        .external(name: "MessagePack")
      ]
    ),
  ],
  additionalFiles: ["Templates/**"]
)
