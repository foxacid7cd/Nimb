import ArgumentParser
import Combine
import Foundation
import Library
import MessagePack
import PathKit
import Procedures
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
  
  private func fetchAPIInfo() async throws -> APIInfo {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = ["-c", "nvim --api-info"]
    
    let inputPipe = Pipe()
    process.standardInput = inputPipe
    
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    
    let errorPipe = Pipe()
    process.standardError = errorPipe
    
    let result = Future<APIInfo, Error> { fulfill in
      var outputAccumulator = Data()
      outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
        let data = fileHandle.availableData
        
        if !data.isEmpty {
          outputAccumulator += data
          return
        }
        
        outputPipe.fileHandleForReading.readabilityHandler = nil
        
        do {
          let (value, remainder) = try unpack(outputAccumulator)
          guard remainder.isEmpty else {
            throw "nvim API info stdout is not one message pack value."
          }
          guard let dictionary = try value.makeJSON() as? [String: Any] else {
            throw "nvim API info stdout is not a message pack map."
          }
          let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
          let apiInfo = try JSONDecoder().decode(APIInfo.self, from: jsonData)
          fulfill(.success(apiInfo))
          
        } catch {
          fulfill(.failure(error))
        }
      }
    }
    
    errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
      let data = fileHandle.availableData
      guard !data.isEmpty else {
        errorPipe.fileHandleForReading.readabilityHandler = nil
        return
      }
      print("nvim stderr:", String(data: data, encoding: .utf8) ?? "nil")
    }
    
    try process.run()
    
    return try await result.value
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
      return "Value"
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
