import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Nims",
  organizationName: "foxacid7cd",
  options: .options(
    automaticSchemesOptions: .disabled,
    textSettings: .textSettings(
      usesTabs: false,
      indentWidth: 2,
      tabWidth: 2,
      wrapsLines: true
    )
  ),
  targets: [
    .nimsTarget(
      name: "Nims",
      product: .app(infoPlist: .default),
      dependencies: [
        .target(name: "Library"),
        .target(name: "Client")
      ]
    ),
    .nimsTarget(
      name: "Client",
      product: .library,
      dependencies: [
        .target(name: "Library"),
        .target(name: "Procedures")
      ],
      hasGeneratedSources: true,
      hasBuildSupportAssets: true
    ),
    .nimsTarget(
      name: "neogen",
      product: .commandLineTool,
      dependencies: [
        .target(name: "Library"),
        .target(name: "Procedures"),
        .external(name: "Stencil"),
        .external(name: "ArgumentParser")
      ]
    ),
    .nimsTarget(
      name: "Procedures",
      product: .library,
      dependencies: [
        .target(name: "Library"),
        .target(name: "Conversations")
      ]
    ),
    .nimsTarget(
      name: "Conversations",
      product: .library,
      dependencies: [
        .target(name: "Library"),
        .external(name: "MessagePack")
      ]
    ),
    .nimsTarget(
      name: "Library",
      product: .library
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
          launchArguments: [
            "/opt/homebrew/bin/nvim",
            "${PROJECT_DIR}/Targets/Client/Support/Templates",
            "${PROJECT_DIR}/Targets/Client/Generated"
          ]
          .map { .init(name: $0, isEnabled: true) }
        )
      ),
      archiveAction: nil,
      profileAction: nil,
      analyzeAction: nil
    )
  ]
)
