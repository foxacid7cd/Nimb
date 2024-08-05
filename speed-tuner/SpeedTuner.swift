// SPDX-License-Identifier: MIT

import ArgumentParser
import Foundation
import CustomDump
import AppKit
import System

@main
struct SpeedTuner: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "speed-tuner",
    shouldDisplay: true,
    subcommands: []
  )
  
  func run() async throws {
    let assetsDirectoryURL = Bundle.main.bundleURL.appending(component: "speed-tuner-assets", directoryHint: .isDirectory)
    let dataFileURL = assetsDirectoryURL.appending(component: "data.mpack", directoryHint: .notDirectory)
    let data = try Data(contentsOf: dataFileURL)
    
    let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 1024 * 1024, alignment: 1024 * 16)
    data.copyBytes(to: buffer)
    if data.count > buffer.count {
      throw NoMemoryError()
    }
    
    let unpacker = Unpacker()
    var isCancelled = false
    var source = buffer.baseAddress!
    var bytesCount = data.count
    while !isCancelled {
      let (value, bytesUsed) = try unpacker._unpack(source: buffer.baseAddress!, bytesCount: data.count)
      bytesCount -= bytesUsed
      if bytesCount <= 0 {
        assert(bytesCount == 0, "Used bytes inconsistency")
        isCancelled = true
      } else {
        source = source.advanced(by: bytesUsed)
      }
      if let value {
        customDump(value)
      }
    }
    
//    let fileHandle = try FileHandle(forReadingFrom: dataFileURL)
//    
//    let outputFileURL = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).txt")
//    FileManager.default.createFile(atPath: outputFileURL.path(), contents: nil)
//    let outputFileHandle = try FileHandle(forWritingTo: outputFileURL)
//    
//    let unpacker = Unpacker()
//    for dataBatch in [data] {
//      let unpacked = try unpacker.unpack(dataBatch)
//      
//      var string = ""
//      customDump(unpacked, to: &string)
//      
//      let data = string.data(using: .utf8)!
//      try outputFileHandle.write(contentsOf: data)
//    }
//    
//    try outputFileHandle.synchronize()
//    try outputFileHandle.close()
//    
//    NSWorkspace.shared.open(outputFileURL)
  }
}

struct NoMemoryError: Error { }
