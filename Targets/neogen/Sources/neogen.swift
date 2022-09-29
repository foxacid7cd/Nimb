import Foundation
import MessagePack
import Stencil
import ArgumentParser
import Library
import Procedures

@main
struct neogen: AsyncParsableCommand {
  @Argument(help: "Path to nvim executable.", completion: .file(extensions: ["nvim"]))
  var nvim: String
  
  @Argument(help: "Directory with templates.", completion: .directory)
  var templatesDirectory: String
  
  @Argument(help: "Directory for generated source code files.", completion: .directory)
  var outputDirectory: String
  
  mutating func run() async throws {
    struct Article {
      let title: String
      let author: String
    }
    
    let context = [
      "articles": [
        Article(title: "Migrating from OCUnit to XCTest", author: "Kyle Fuller"),
        Article(title: "Memory Management with ARC", author: "Kyle Fuller"),
      ]
    ]
    
    let env = Environment(loader: FileSystemLoader(paths: [.init(templatesDirectory)]), templateClass: Template.self, trimBehaviour: .smart)
    let rendered = try env.renderTemplate(name: "Template.stencil", context: context)
    
    let url = URL(fileURLWithPath: outputDirectory, isDirectory: true)
    let fileUrl = url.appendingPathComponent("output.txt", isDirectory: false)
    try rendered.data(using: .utf8)!.write(to: fileUrl, options: [])
  }
  
  static func _main() async throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/nvim")
    process.arguments = ["--api-info"]
    
    let inputPipe = Pipe()
    process.standardInput = inputPipe
    
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    
    let errorPipe = Pipe()
    process.standardError = errorPipe
    
    var outputAccumulator = Data()
    outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
      let data = fileHandle.availableData
      guard !data.isEmpty else {
        outputPipe.fileHandleForReading.readabilityHandler = nil
        
        do {
          let (value, remainder) = try unpack(outputAccumulator)
          assert(remainder.isEmpty, "Entire stdout output is expected to be one message pack object.")
          let json = try jsonify(value: value)
          guard let dictionary = json as? [String: Any] else {
            throw "Not a top level dictionary."
          }
          let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
          let nvimApiInfo = try JSONDecoder().decode(NvimAPIInfo.self, from: jsonData)
          let types = nvimApiInfo.functions.flatMap { $0.parameters.map { $0.type } } +
            nvimApiInfo.uiEvents.flatMap { $0.parameters.map { $0.type } } +
            nvimApiInfo.functions.map { $0.returnType }
          let unique_types = Set(types)
          print(unique_types)
          
        } catch {
          print("Could not unpack accumulated output, \(error).")
        }
        
        return
      }
      outputAccumulator += data
    }
    
    errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
      let data = fileHandle.availableData
      guard !data.isEmpty else {
        errorPipe.fileHandleForReading.readabilityHandler = nil
        return
      }
      print("stderr:", String(data: data, encoding: .utf8) ?? "nil")
    }
    
    Task {
      try process.run()
    }
    
    RunLoop.main.run()
  }
}

private func jsonify(value: MessagePackValue) throws -> Any {
  switch value {
    case .nil:
      throw "Unsupported nil value type."
      
    case let .bool(value):
      return value
      
    case let .int(value):
      return Int(value)
      
    case let .uint(value):
      return UInt(value)
      
    case let .float(value):
      return value
      
    case let .double(value):
      return value
      
    case let .string(value):
      return value
      
    case let .binary(value):
      return value
      
    case let .array(value):
      return try value.map { try jsonify(value: $0) }
      
    case let .map(value):
      var dictionary = [String: Any]()
      try value
        .forEach { key, value in
          guard let key = key.stringValue else {
            throw "Unsupported map key, \(key), \(value)."
          }
          dictionary[key] = try jsonify(value: value)
        }
      return dictionary
      
    case .extended:
      throw "Unsupported extended value type."
  }
}
