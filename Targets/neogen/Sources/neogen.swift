import Foundation
import Combine
import ArgumentParser
import Library
import MessagePack
import PathKit
import Procedures
import Stencil

@main
struct neogen: AsyncParsableCommand {
  @Argument(help: "Path to nvim executable.", completion: .file(extensions: ["nvim"]))
  var nvim: String
  
  @Argument(help: "Path to templates directory.", completion: .directory)
  var templates: String
  
  @Argument(help: "Path to directory for generated output files.", completion: .directory)
  var output: String
  
  mutating func run() async throws {
    let rawNvimAPIInfo = try await fetchRawNvimAPIInfo()
    let renderingContext = try makeRenderingContext(rawNvimAPIInfo: rawNvimAPIInfo)
    try generateOutputFiles(renderingContext: renderingContext)
  }
  
  private func fetchRawNvimAPIInfo() async throws -> [MessagePackValue: MessagePackValue] {
    let process = Process()
    process.executableURL = Path(nvim).url
    process.arguments = ["--api-info"]
    
    let inputPipe = Pipe()
    process.standardInput = inputPipe
    
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    
    let errorPipe = Pipe()
    process.standardError = errorPipe
    
    let result = Future<[MessagePackValue: MessagePackValue], Error> { fulfill in
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
          guard let dictionaryValue = value.dictionaryValue else {
            throw "nvim API info stdout is not a message pack map."
          }
          fulfill(.success(dictionaryValue))
          
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
    let templatesPath = Path(templates)
    guard templatesPath.isDirectory, templatesPath.isReadable else {
      throw "Could not access templates directory."
    }
    
    let outputPath = Path(output)
    guard outputPath.isDirectory, outputPath.isWritable else {
      throw "Could not access output directory."
    }
    
    let environment = Environment(
      loader: FileSystemLoader(paths: [templatesPath]),
      trimBehaviour: .smart
    )
    
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
      
      print(outputFilePath)
    }
  }
}

private func makeRenderingContext(rawNvimAPIInfo: [MessagePackValue: MessagePackValue]) throws -> [String: Any] {
  return try process(value: .map(rawNvimAPIInfo)) as! [String: Any]
  
  func process(value: MessagePackValue) throws -> Any {
    switch value {
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
        return try value.map { try process(value: $0) }
        
      case let .map(value):
        var dictionary = [String: Any]()
        try value
          .forEach { key, value in
            guard let key = key.stringValue else {
              throw "Unsupported map key, \(key), \(value)."
            }
            dictionary[key] = try process(value: value)
          }
        return dictionary
        
      case .extended:
        throw "Unsupported extended value type."
        
      case .nil:
        throw "Unsupported nil value type."
    }
  }
}
