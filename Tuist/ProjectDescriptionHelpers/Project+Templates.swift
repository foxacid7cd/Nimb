import ProjectDescription

public enum NimsProduct {
  case app(infoPlist: InfoPlist)
  case commandLineTool
  case library
}

extension Target {
  public static func nimsTarget(
    name: String,
    product: NimsProduct,
    dependencies: [TargetDependency] = [],
    hasDevelopmentAssets: Bool = false
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
      sources: ["Targets/\(name)/Sources/**"],
      resources: {
        switch product {
          case .app:
            return ["Targets/\(name)/Resources/**"]
          default:
            return []
        }
      }(),
      dependencies: dependencies,
      settings: .settings(),
      additionalFiles: hasDevelopmentAssets ? ["Targets/\(name)/Development/**"] : []
    )
  }
}
