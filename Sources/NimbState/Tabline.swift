// SPDX-License-Identifier: MIT

import NimbCore
import NimbNeovim

@PublicInit
public struct Tabline: Sendable, Hashable {
  public var currentTabpageID: Tabpage.ID
  public var tabpages: [Tabpage]
  public var currentBufferID: Buffer.ID
  public var buffers: [Buffer]
}
