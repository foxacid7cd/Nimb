// SPDX-License-Identifier: MIT

public enum NeovimNotification: Sendable, Equatable {
  case redraw([UIEvent])
  case nvimErrorEvent(NeovimErrorEvent)
}
