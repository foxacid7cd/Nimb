//
//  DispatchQueues.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 24.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import RxSwift

enum DispatchQueues {
  static let GlyphRunCache = makeDispatchQueue("GlyphRunCache", attributes: .concurrent)
  static let StateDerivatives = makeDispatchQueue("StateDerivatives", attributes: .concurrent)
  static let GridViewSynchronization = makeDispatchQueue("GridViewSynchronization", qos: .userInitiated, attributes: .concurrent)
  static let Nvim = makeDispatchQueue("Nvim", qos: .userInitiated)
}

private func makeDispatchQueue(
  _ name: String,
  qos: DispatchQoS = .default,
  attributes: DispatchQueue.Attributes = []
) -> (dispatchQueue: DispatchQueue, scheduler: SerialDispatchQueueScheduler) {
  let label = "\(Bundle.main.bundleIdentifier!).\(name)"
  let dispatchQueue = DispatchQueue(
    label: label,
    qos: qos,
    attributes: attributes
  )
  let scheduler = SerialDispatchQueueScheduler(queue: dispatchQueue, internalSerialQueueName: "\(label).Scheduler")
  return (dispatchQueue, scheduler)
}
