//
//  NvimServiceProtocol.swift
//  NvimServiceAPI
//
//  Created by Yevhenii Matviienko on 22.11.2022.
//

import Foundation

@objc public protocol NvimServiceProtocol: AnyObject {
  func startNvim(arguments: [String], _ callback: @escaping () -> Void)
}
