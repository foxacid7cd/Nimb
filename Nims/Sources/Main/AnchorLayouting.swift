// SPDX-License-Identifier: MIT

import Foundation

public protocol AnchorLayoutingLayer: AnyObject {
  var anchoringLayer: AnchorLayoutingLayer? { get set }
  var anchoredLayers: [ObjectIdentifier: AnchorLayoutingLayer] { get set }
  var positionInAnchoringLayer: CGPoint { get set }

  func layoutAnchoredLayers(anchoringLayerOrigin: CGPoint)
}
