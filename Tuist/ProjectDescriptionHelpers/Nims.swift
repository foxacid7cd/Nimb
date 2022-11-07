import ProjectDescription

public enum NimsProduct {
  case app(infoPlist: InfoPlist)
  case commandLineTool
  case library
  case nvim
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

        case .nvim:
          return .bundle
        }
      }(),
      bundleId: [
        "foxacid7cd.Nims",
        {
          switch product {
          case .app:
            return nil

          default:
            return name
          }
        }()
      ]
      .compactMap { $0 }
      .joined(separator: "."),
      deploymentTarget: .macOS(targetVersion: "12.3"),
      infoPlist: {
        switch product {
        case let .app(infoPlist):
          return infoPlist

        default:
          return .default
        }
      }(),
      sources: {
        switch product {
        case .nvim:
          return nil

        default:
          return .init(
            globs: [
              "Targets/\(name)/Sources/**",
              hasGeneratedSources ? "Targets/\(name)/Generated/**" : nil
            ]
            .compactMap { $0 }
          )
        }
      }(),
      resources: {
        switch product {
        case .app:
          return [
            .glob(pattern: "Targets/\(name)/Resources/**")
          ]

        default:
          return []
        }
      }(),
      copyFiles: {
        switch product {
        case .nvim:
          return [
            .executables(
              name: "Copy nvim",
              files: [
                .glob(pattern: "Targets/\(name)/nvim")
              ]
            ),
            .resources(
              name: "Copy runtime",
              files: [
                .folderReference(path: "Targets/\(name)/runtime")
              ]
            )
          ]

        default:
          return nil
        }
      }(),
      entitlements: {
        switch product {
        case .app, .nvim:
          return "Entitlements/\(name).entitlements"

        default:
          return nil
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
