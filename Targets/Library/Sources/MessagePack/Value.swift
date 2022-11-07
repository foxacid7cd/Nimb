//
//  Value.swift
//  Library
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import MessagePack
import RxSwift

public typealias Value = MessagePackValue

public extension Value {
  var data: Data {
    pack(self)
  }
}

extension Value: Error {}
