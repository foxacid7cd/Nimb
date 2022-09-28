//
//  log.swift
//  
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//

import OSLog

private let sharedLog = OSLog(subsystem: "Nims", category: "main")

func log(_ type: OSLogType, _ message: String) {
  os_log(type, log: sharedLog, "\(message)")
}
