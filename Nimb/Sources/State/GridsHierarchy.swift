// SPDX-License-Identifier: MIT

import Collections
import CustomDump
import Overture

@PublicInit
public struct GridsHierarchy: Sendable {
  @PublicInit
  public struct Node: Sendable {
    public var id: Grid.ID
    public var parent: Grid.ID
    public var children: OrderedSet<Grid.ID>
  }

  public var allNodes: IntKeyedDictionary<Node> = .init()

  public mutating func removeNode(id: Grid.ID) {
    guard let node = allNodes.removeValue(forKey: id) else {
      return
    }
    update(&allNodes[node.parent]) { parentNode in
      guard parentNode != nil else {
        return
      }
      parentNode!.children.remove(id)
    }
  }

  public mutating func addNode(id: Grid.ID, parent: Grid.ID) {
    removeNode(id: id)
    allNodes[id] = .init(id: id, parent: parent, children: .init())

    if id != Grid.OuterID {
      update(&allNodes[parent]) { parentNode in
        guard parentNode != nil else {
          Task { @MainActor in
            logger
              .warning(
                "GridsHierarchy.addNode: parent node with id \(parent) not found"
              )
          }
          return
        }
        parentNode!.children.append(id)
      }
    }
  }

  public mutating func bringToFront(id: Grid.ID) {
    guard id != Grid.OuterID, let node = allNodes[id] else {
      return
    }
    update(&allNodes[node.parent]) { parentNode in
      guard parentNode != nil else {
        return
      }
      parentNode!.children.remove(id)
      parentNode!.children.append(id)
    }
  }
}
