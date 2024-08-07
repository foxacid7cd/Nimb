// SPDX-License-Identifier: MIT

public class BufferingStateContainer: StateContainer {
  public init(_ state: State) {
    self.state = state
    bufferedState = state
  }

  public class BufferedView: StateContainer {
    init(_ wrapped: BufferingStateContainer) {
      self.wrapped = wrapped
    }

    public var state: State {
      get {
        wrapped.bufferedState
      }
      set {
        wrapped.bufferedState = newValue
      }
    }

    private let wrapped: BufferingStateContainer
  }

  public var state: State
  public var bufferedState: State

  public var bufferedView: BufferedView {
    .init(self)
  }
}
