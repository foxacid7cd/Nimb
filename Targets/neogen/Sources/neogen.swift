import ArgumentParser
import Combine
import Conversations
import Foundation
import Library
import MessagePack
import PathKit
import Stencil

@main
struct neogen: AsyncParsableCommand {
  @Argument
  var project: String
  
  mutating func run() async throws {
    try generateOutputFiles(
      renderingContext: try renderingContext(
        apiInfo: try await fetchAPIInfo()
      )
    )
  }
  
  @MainActor
  private func fetchAPIInfo() async throws -> APIInfo {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", "nvim --api-info"]
    
    let inputPipe = Pipe()
    process.standardInput = inputPipe
    
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
        guard let string = String(data: data, encoding: .utf8) else {
          fatalError("Could not decode UTF-8 string from nvim stderr.")
        }
        print("nvim stderr -> \(string)")
      }
    }
    
    try process.run()
    
    return try await apiInfoTask.value
  }
  
  private func generateOutputFiles(renderingContext: [String: Any]) throws {
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
  }
}

private func renderingContext(apiInfo: APIInfo) throws -> [String: Any] {
  return [
    "functions": apiInfo.functions
      .map { function in
        var dictionary = [
          "name": function.name,
          "parametersArray": function.parameters
            .map { obtainingValue(nvimType: $0.type, name: $0.name.camelCased) }
            .joined(separator: ", "),
          "signature": {
            let formattedParameters = function.parameters
              .map { "\($0.name.camelCased): \(swiftType(nvimType: $0.type))" }
              .joined(separator: ", ")
            
            return [
              "func \(function.name.camelCased)(\(formattedParameters)) async throws",
              function.returnType == "void" ? nil : swiftType(nvimType: function.returnType)
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
              function.returnType == "void" ? nil : function.returnType
            ]
            .compactMap { $0 }
            .joined(separator: " -> ")
          }(),
          "isDeprecated": function.deprecatedSince != nil
        ]
        if function.returnType != "void" {
          dictionary["returnType"] = swiftType(nvimType: function.returnType)
          dictionary["obtainingReturnValue"] = obtainingReturnValue(nvimType: function.returnType, name: "result")
        }
        return dictionary
      }
  ]
}

extension String {
  var camelCased: String {
    split(separator: "_")
      .enumerated()
      .map { index, word in index == 0 ? String(word) : word.capitalized }
      .joined()
  }
}

extension MessagePackValue {
  func makeJSON() throws -> Any {
    switch self {
      case let .array(array):
        return try array.map { try $0.makeJSON() }
        
      case let .map(map):
        var dictionary = [String: Any]()
        for (key, value) in map {
          guard let key = key.stringValue else {
            throw "Unsupported map key type."
          }
          dictionary[key] = try value.makeJSON()
        }
        return dictionary
        
      case let .bool(value):
        return value
        
      case let .double(value):
        return value
        
      case let .float(value):
        return value
        
      case let .string(value):
        return value
        
      case let .int(value):
        return value
        
      case let .uint(value):
        return UInt(value)
        
      case .extended, .binary, .nil:
        throw "Unsupported value type."
    }
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
