import ProjectDescription

func createTarget(name: String, product: Product, dependencies: [TargetDependency] = []) -> Target {
  return .init(name: name, platform: .macOS, product: product, productName: nil, bundleId: "foxacid7cd.\(name)", deploymentTarget: .macOS(targetVersion: "12.3"), infoPlist: .extendingDefault(with: [:]), sources: ["Targets/\(name)/Sources/**"], resources: ["Targets/\(name)/Resources/**"], copyFiles: nil, headers: nil, entitlements: nil, scripts: [], dependencies: dependencies, settings: nil, coreDataModels: [], environment: [:], launchArguments: [], additionalFiles: [])
}

let project = Project(
  name: "Nims",
  organizationName: "foxacid7cd",
  options: .options(
    automaticSchemesOptions: .enabled(),
    developmentRegion: "UA",
    textSettings: .textSettings(
      usesTabs: false,
      indentWidth: 2,
      tabWidth: 2,
      wrapsLines: true
    ),
    xcodeProjectName: "Nims"
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
      name: "Procedures",
      product: .framework,
      dependencies: [
        .target(name: "Conversations")
      ]
    ),
    createTarget(
      name: "Conversations",
      product: .framework,
      dependencies: [
        .external(name: "MessagePack")
      ]
    ),
  ],
  schemes: [],
  fileHeaderTemplate: .none,
  additionalFiles: [],
  resourceSynthesizers: []
)
