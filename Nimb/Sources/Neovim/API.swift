// SPDX-License-Identifier: MIT

public final class API<Target: Channel>: Sendable {
  public let neovimNotifications: AsyncThrowingStream<[NeovimNotification], any Error>

  let rpc: RPC<Target>

  public init(_ rpc: RPC<Target>) {
    self.rpc = rpc
    neovimNotifications = rpc.notifications
      .map { notifications -> [NeovimNotification] in
        try notifications.compactMap { notification in
          switch notification.method {
          case "redraw":
            let uiEvents =
              try [UIEvent](
                rawRedrawNotificationParameters: notification
                  .parameters
              )
            return .redraw(uiEvents)

          case "nvim_error_event":
            let nvimErrorEvent = try NeovimErrorEvent(
              parameters: notification
                .parameters
            )
            return .nvimErrorEvent(nvimErrorEvent)

          case "nimb_notify":
            let notifies = try notification.parameters
              .map { try NimbNotify($0) }
            return .nimbNotify(notifies)

          default:
            return nil
          }
        }
      }
      .buffer(policy: .unbounded)
      .eraseToThrowingStream()
  }

  @discardableResult
  public func call<T: APIFunction>(_ apiFunction: T) async throws -> T.Success {
    try await rpc.call(
      method: T.method,
      withParameters: apiFunction.parameters
    )
    .map(T.decodeSuccess(from:), NeovimError.init(raw:))
  }

  @MainActor
  public func fastCall<T: APIFunction>(_ apiFunction: T) throws {
    try rpc.fastCall(
      method: T.method,
      withParameters: apiFunction.parameters
    )
  }

  @MainActor
  public func fastCallsTransaction(
    with apiFunctions: some Sequence<any APIFunction>
  ) throws {
    try rpc.fastCallsTransaction(with: apiFunctions.map {
      (
        method: type(of: $0).method,
        parameters: $0.parameters
      )
    })
  }
}
