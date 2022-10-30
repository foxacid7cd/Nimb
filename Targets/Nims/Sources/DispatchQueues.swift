//
//  DispatchQueues.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 24.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation

enum DispatchQueues {
  static let GlyphRunsCache = makeDispatchQueue("GlyphRunsCache", attributes: .concurrent)
  static let CGColorCache = makeDispatchQueue("CGColorCache", attributes: .concurrent)
  static let StateDerivatives = makeDispatchQueue("StateDerivatives", attributes: .concurrent)
  static let SerialDrawing = makeDispatchQueue("SerialDrawing", attributes: .concurrent)
}

private func makeDispatchQueue(
  _ name: String,
  qos: DispatchQoS = .default,
  attributes: DispatchQueue.Attributes = []
) -> DispatchQueue {
  .init(
    label: "\(Bundle.main.bundleIdentifier!).\(name)",
    qos: qos,
    attributes: attributes
  )
}
