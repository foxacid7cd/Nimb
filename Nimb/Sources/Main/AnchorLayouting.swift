// SPDX-License-Identifier: MIT

import Foundation

public protocol AnchorLayoutingLayer: AnyObject {
  @MainActor
  var anchoringLayer: AnchorLayoutingLayer? { get set }
  @MainActor
  var anchoredLayers: [ObjectIdentifier: AnchorLayoutingLayer] { get set }
  @MainActor
  var positionInAnchoringLayer: CGPoint { get set }
  @MainActor
  var needsAnchorLayout: Bool { get set }

  @MainActor
  func layoutAnchoredLayers(anchoringLayerOrigin: CGPoint, zIndexCounter: Double)
}
