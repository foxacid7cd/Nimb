// SPDX-License-Identifier: MIT

import OSLog

@MainActor let logger = Logger()
@MainActor let signposter = OSSignposter(logger: logger)
