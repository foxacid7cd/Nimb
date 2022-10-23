import ProjectDescription

public enum NimsProduct {
  case app(infoPlist: InfoPlist)
  case commandLineTool
  case library
}

public extension Target {
  static func nimsTarget(
    name: String,
    product: NimsProduct,
    scripts: [TargetScript] = [],
    dependencies: [TargetDependency] = [],
    hasGeneratedSources: Bool = false,
    hasDevelopmentAssets: Bool = false,
    hasBuildSupportAssets: Bool = false
  ) -> Target {
    .init(
      name: name,
      platform: .macOS,
      product: {
        switch product {
        case .app:
          return .app
        case .commandLineTool:
          return .commandLineTool
        case .library:
          return .staticLibrary
        }
      }(),
      bundleId: "foxacid7cd.\(name)",
      deploymentTarget: .macOS(targetVersion: "12.3"),
      infoPlist: {
        switch product {
        case let .app(infoPlist):
          return infoPlist
        default:
          return .default
        }
      }(),
      sources: .init(
        globs: [
          "Targets/\(name)/Sources/**",
          hasGeneratedSources ? "Targets/\(name)/Generated/**" : nil
        ]
        .compactMap { $0 }
      ),
      resources: {
        switch product {
        case .app:
          return [
            .glob(pattern: "Targets/\(name)/Resources/**"),
            .folderReference(path: "Targets/\(name)/runtime")
          ]
        default:
          return []
        }
      }(),
      scripts: scripts,
      dependencies: dependencies,
      settings: .settings(defaultSettings: .recommended),
      additionalFiles: [
        hasDevelopmentAssets ? "Targets/\(name)/Development/**" : nil,
        hasBuildSupportAssets ? "Targets/\(name)/Support/**" : nil
      ]
      .compactMap { $0 }
    )
  }
}
