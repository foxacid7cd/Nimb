import Foundation
import MessagePack
import Stencil
import Procedures

@main
struct neogen {
  static func main() async throws {
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
          assert(remainder.isEmpty, "Entire stdout output must be one message pack object")
          let json = try jsonify(value: value)
          guard let dictionary = json as? [String: Any] else {
            throw JsonifyError(description: "Not a top level dictionary.")
          }
          let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
          let nvimApiInfo = try JSONDecoder().decode(NvimApiInfo.self, from: jsonData)
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
      throw JsonifyError(description: "Unsupported nil value type.")
      
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
            throw JsonifyError(description: "Unsupported map key, \(key), \(value).")
          }
          dictionary[key] = try jsonify(value: value)
        }
      return dictionary
      
    case .extended:
      throw JsonifyError(description: "Unsupported extended value type.")
  }
}

struct JsonifyError: Error, CustomStringConvertible {
  var description: String
}
