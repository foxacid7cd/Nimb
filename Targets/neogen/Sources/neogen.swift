import ArgumentParser
import AsyncAlgorithms
import Combine
import Conversations
import Foundation
import Library
import MessagePack
import PathKit
import Stencil

private let ArrayUIEvents = ["option_set", "mode_info_set", "highlight_set", "default_colors_set", "hl_group_set", "hl_attr_define", "grid_resize", "grid_clear", "msg_set_pos", "grid_line", "win_viewport"]

@main
struct neogen: AsyncParsableCommand {
  @Argument
  var project: String

  mutating func run() async throws {
    let apiInfo = try await fetchAPIInfo()
    let renderingContext = try renderingContext(apiInfo: apiInfo)
    let outputFilePathes = try generateOutputFiles(renderingContext: renderingContext)
    try await formatSourceFiles(filePathes: outputFilePathes)
  }

  @MainActor
  private func formatSourceFiles(filePathes: Set<Path>) async throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    let formattedFilePathes = filePathes
      .map { $0.string }
      .joined(separator: " ")
    process.arguments = ["-c", "swiftformat \(formattedFilePathes) --swiftversion 5.7.1"]

    let terminationChannel = AsyncThrowingChannel<Void, Error>()
    process.terminationHandler = { process in
      if process.terminationStatus == 0 {
        terminationChannel.finish()

      } else {
        terminationChannel.fail("swiftformat process failed with exit code \(process.terminationStatus).")
      }
    }

    try process.run()

    for try await _ in terminationChannel {}
  }

  @MainActor
  private func fetchAPIInfo() async throws -> APIInfo {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", "nvim --api-info"]

    let outputPipe = Pipe()
    process.standardOutput = outputPipe

    let errorPipe = Pipe()
    process.standardError = errorPipe

    let apiInfoTask = Task<APIInfo, Error>.detached {
      let outputData = try await AsyncFileData(outputPipe.fileHandleForReading)
        .reduce(into: Data()) { $0 += $1 }

      let (value, remainder) = try unpack(outputData)
      guard remainder.isEmpty else {
        throw "nvim API info stdout is not one message pack value."
      }
      guard let dictionary = try value.makeJSON() as? [String: Any] else {
        throw "nvim API info stdout is not a message pack map."
      }
      let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
      return try JSONDecoder().decode(APIInfo.self, from: jsonData)
    }

    Task {
      for try await data in AsyncFileData(errorPipe.fileHandleForReading) {
        print("stderr >> \(String(data: data, encoding: .utf8)!)")
      }
    }

    try process.run()

    return try await apiInfoTask.value
  }

  private func generateOutputFiles(renderingContext: [String: Any]) throws -> Set<Path> {
    let projectPath = Path(project)
    guard projectPath.isDirectory else {
      throw "Could not access project directory."
    }

    let apiTargetPath = projectPath + "Targets/API"
    let templatesPath = apiTargetPath + "Support/Templates"
    let outputPath = apiTargetPath + "Generated"

    let oldGeneratedFiles = Set(try outputPath.children())

    let environment = Environment(
      loader: FileSystemLoader(paths: [templatesPath])
    )

    var generatedFiles = Set<Path>()
    for templatePath in try templatesPath.children() {
      guard templatePath.isFile, templatePath.extension == "stencil", templatePath.isReadable else {
        continue
      }

      let renderedTemplate = try environment.renderTemplate(
        name: templatePath.lastComponent,
        context: renderingContext
      )

      let outputFilePath = outputPath + "\(templatePath.lastComponentWithoutExtension).swift"
      try outputFilePath.write(renderedTemplate.data(using: .utf8)!)
      generatedFiles.insert(outputFilePath)
    }

    for file in generatedFiles {
      print("+ \(file)")
    }

    for file in oldGeneratedFiles.subtracting(generatedFiles) {
      try file.delete()
      print("- \(file)")
    }

    return generatedFiles
  }
}

private func renderingContext(apiInfo: APIInfo) throws -> [String: Any] {
  var dictionary: [String: Any] = [
    "functions": apiInfo.functions
      .map { function in
        var dictionary = [
          "name": function.name.camelCased(capitalized: false),
          "originalName": function.name,
          "parameters": function.parameters
            .map { parameter in
              [
                "name": parameter.name.camelCased(capitalized: false),
                "type": swiftType(nvimType: parameter.type),
                "obtainingValue": obtainingReturnValue(nvimType: parameter.type, name: ""),
              ]
            },
          "parametersInitializationSignature": function.parameters
            .map { obtainingValue(nvimType: $0.type, name: $0.name.camelCased(capitalized: false)) }
            .joined(separator: ", "),
          "signature": {
            let formattedParameters = function.parameters
              .map { "\($0.name.camelCased(capitalized: false)): \(swiftType(nvimType: $0.type))" }
              .joined(separator: ", ")

            return [
              "func \(function.name.camelCased(capitalized: false))(\(formattedParameters)) async throws",
              function.returnType == "void" ? nil : swiftType(nvimType: function.returnType),
            ]
            .compactMap { $0 }
            .joined(separator: " -> ")
          }(),
          "description": {
            let formattedParameters = function.parameters
              .map { "\($0.name): \($0.type)" }
              .joined(separator: ", ")

            return [
              "\(function.name)(\(formattedParameters))",
              function.returnType == "void" ? nil : function.returnType,
            ]
            .compactMap { $0 }
            .joined(separator: " -> ")
          }(),
          "isDeprecated": function.deprecatedSince != nil,
        ]
        if function.returnType != "void" {
          dictionary["returnType"] = swiftType(nvimType: function.returnType)
          dictionary["obtainingReturnValue"] = obtainingReturnValue(nvimType: function.returnType, name: "result")
        }
        return dictionary
      },
  ]

  var uiEvents = [Any]()
  var uiEventModels = [Any]()
  for uiEvent in apiInfo.uiEvents {
    let isArray = ArrayUIEvents.contains(uiEvent.name)
    let description: String = {
      guard !uiEvent.parameters.isEmpty else {
        return uiEvent.name
      }

      let formattedParameters = uiEvent.parameters
        .map { "\($0.name): \($0.type)" }
        .joined(separator: ", ")

      return "\(uiEvent.name)(\(formattedParameters))"
    }()
    enum SignatureType {
      case declaration
      case initialization
    }

    var dictionary: [String: Any] = [
      "description": description,
      "name": uiEvent.name.camelCased(capitalized: false),
      "originalName": uiEvent.name,
      "isArray": isArray,
      "parameters": uiEvent.parameters
        .map { parameter in
          [
            "name": parameter.name.camelCased(capitalized: false),
            "type": swiftType(nvimType: parameter.type),
            "obtainingValue": obtainingReturnValue(nvimType: parameter.type, name: ""),
          ]
        },
    ]

    if !uiEvent.parameters.isEmpty {
      dictionary["parametersType"] = {
        if isArray {
          var name = uiEvent.name

          let setSuffix = "_set"
          if name.hasSuffix(setSuffix) {
            name = String(name.prefix(name.count - setSuffix.count))
          }

          if name.hasSuffix("s") {
            name.removeLast()
          }

          return name.camelCased(capitalized: true)
        } else {
          return uiEvent.name.camelCased(capitalized: true)
        }
      }()
    }

    uiEvents.append(dictionary)
    if !uiEvent.parameters.isEmpty {
      uiEventModels.append(dictionary)
    }
  }
  dictionary["uiEvents"] = uiEvents
  dictionary["uiEventModels"] = uiEventModels

  return dictionary
}

extension StringProtocol {
  func camelCased(capitalized: Bool) -> String {
    split(separator: "_")
      .enumerated()
      .map { index, word in
        if !capitalized, index == 0 {
          return String(word)
        }

        switch word {
        case "ui", "id", "api":
          return word.uppercased()

        default:
          return word.capitalized
        }
      }
      .joined()
  }
}

private func swiftType(nvimType: String) -> String {
  switch nvimType {
  case "Boolean":
    return "Bool"
  case "String":
    return "String"
  case "Integer":
    return "Int"
  case "Array":
    return "[MessagePackValue]"
  default:
    return "MessagePackValue"
  }
}

private func obtainingValue(nvimType: String, name: String) -> String {
  switch nvimType {
  case "Boolean":
    return ".bool(\(name))"
  case "String":
    return ".string(\(name))"
  case "Integer":
    return ".int(Int64(\(name)))"
  case "Array":
    return ".array(\(name))"
  default:
    return name
  }
}

private func obtainingReturnValue(nvimType: String, name: String) -> String {
  switch nvimType {
  case "Boolean":
    return "\(name).boolValue"
  case "String":
    return "\(name).stringValue"
  case "Integer":
    return "\(name).intValue"
  case "Array":
    return "\(name).arrayValue"
  default:
    return name
  }
}

private struct APIInfo: Decodable {
  var errorTypes: [String: ErrorType]
  var uiOptions: [String]
  var functions: [Function]
  var types: [String: Type]
  var uiEvents: [UIEvent]

  struct ErrorType: Decodable {
    var id: Int
  }

  enum CodingKeys: String, CodingKey {
    case errorTypes = "error_types"
    case uiOptions = "ui_options"
    case functions
    case types
    case uiEvents = "ui_events"
  }

  struct Function: Decodable {
    var deprecatedSince: Int?
    var method: Bool
    var name: String
    var parameters: [Parameter]
    var returnType: String
    var since: Int

    enum CodingKeys: String, CodingKey {
      case deprecatedSince = "deprecated_since"
      case method
      case name
      case parameters
      case returnType = "return_type"
      case since
    }
  }

  struct `Type`: Decodable {
    var id: Int
    var prefix: String
  }

  struct UIEvent: Decodable {
    var name: String
    var parameters: [Parameter]
    var since: Int
  }

  struct Version: Decodable {
    var apiCompatible: Int
    var apiLevel: Int
    var apiPrerelease: Bool
    var major: Int
    var minor: Int
    var patch: Int
    var prerelease: Bool

    enum CodingKeys: String, CodingKey {
      case apiCompatible = "api_compatible"
      case apiLevel = "api_level"
      case apiPrerelease = "api_prerelease"
      case major
      case minor
      case patch
      case prerelease
    }
  }

  struct Parameter: Decodable {
    var type: String
    var name: String

    init(type: String, name: String) {
      self.type = type
      self.name = name
    }

    init(from decoder: Decoder) throws {
      var container: UnkeyedDecodingContainer = try decoder.unkeyedContainer()
      type = try container.decode(String.self)
      name = try container.decode(String.self)
    }
  }
}
