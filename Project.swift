import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Nims",
  organizationName: "foxacid7cd",
  options: .options(
    textSettings: .textSettings(
      usesTabs: false,
      indentWidth: 2,
      tabWidth: 8,
      wrapsLines: true
    )
  ),
  targets: [
    .nimsTarget(
      name: "Nims",
      product: .app(
        infoPlist: .extendingDefault(
          with: [
            "NSMainStoryboardFile": "",
            "NSMainNibFile": "MainMenu"
          ]
        )
      ),
      scripts: [],
      dependencies: [
        .target(name: "Library"),
        .target(name: "API")
      ]
    ),
    .nimsTarget(
      name: "API",
      product: .library,
      dependencies: [
        .target(name: "Library")
      ],
      hasGeneratedSources: true,
      hasBuildSupportAssets: true
    ),
    .nimsTarget(
      name: "neogen",
      product: .commandLineTool,
      dependencies: [
        .target(name: "Library"),
        .external(name: "Stencil"),
        .external(name: "ArgumentParser")
      ]
    ),
    .nimsTarget(
      name: "Library",
      product: .library,
      dependencies: [
        .external(name: "AsyncAlgorithms"),
        .external(name: "RxSwift"),
        .external(name: "RxCocoa"),
        .external(name: "MessagePack"),
        .external(name: "CasePaths"),
        .external(name: "Socket")
      ]
    ),
    .nimsTarget(
      name: "nvim",
      product: .nvim,
      scripts: [],
      dependencies: []
    )
  ],
  schemes: [
    .init(
      name: "Nims",
      shared: true,
      hidden: false,
      buildAction: .buildAction(
        targets: ["Nims"]
      ),
      testAction: nil,
      runAction: .runAction(configuration: .debug),
      archiveAction: .archiveAction(configuration: .release),
      profileAction: .profileAction(configuration: .release),
      analyzeAction: nil
    ),
    .init(
      name: "neogen",
      shared: true,
      hidden: false,
      buildAction: .buildAction(
        targets: ["neogen"]
      ),
      testAction: nil,
      runAction: .runAction(
        configuration: .debug,
        arguments: .init(
          launchArguments: ["$PROJECT_DIR"]
            .map { .init(name: $0, isEnabled: true) }
        )
      ),
      archiveAction: nil,
      profileAction: nil,
      analyzeAction: nil
    )
  ],
  additionalFiles: [
    .folderReference(path: "Entitlements"),
    .folderReference(path: "Scripts")
  ]
)
