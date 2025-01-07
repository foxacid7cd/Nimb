// SPDX-License-Identifier: MIT

import AppKit
import IOSurface

@objc public protocol RendererProtocol: Sendable {
  @objc func setFont(
    _ font: NSFont,
    cb: @Sendable @escaping (
      _ cellSize: CGSize
    ) -> Void
  )
  @objc func set(
    contentsScale: CGFloat,
    _ cb: @Sendable @escaping (_ isChanged: Bool) -> Void
  )
  @objc func setGridSize(columnsCount: Int, rowsCount: Int, forGridWithID gridID: Int, _ cb: @Sendable @escaping (_ isChanged: Bool) -> Void)
  @objc func draw(
    gridDrawRequest: GridDrawRequest,
    cb: @Sendable @escaping () -> Void
  )
}

/*
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:

     connectionToService = NSXPCConnection(serviceName: "foxacid7cd.Renderer")
     connectionToService.remoteObjectInterface = NSXPCInterface(with: RendererProtocol.self)
     connectionToService.resume()

 Once you have a connection to the service, you can use it like this:

     if let proxy = connectionToService.remoteObjectProxy as? RendererProtocol {
         proxy.performCalculation(firstNumber: 23, secondNumber: 19) { result in
             NSLog("Result of calculation is: \(result)")
         }
     }

 And, when you are finished with the service, clean up the connection like this:

     connectionToService.invalidate()
 */
