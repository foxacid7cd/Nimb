//
//  normalizedToParametersArray.swift
//  Library
//
//  Created by Yevhenii Matviienko on 14.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import MessagePack

public extension Sequence where Element == MessagePackValue {
  var normalizedToParametersArray: [[MessagePackValue]] {
    var parameters = [MessagePackValue]()
    
    var parametersArray = [[MessagePackValue]]()
    var isAssumingParametersArray = true
    
    for parameter in self {
      parameters.append(parameter)
      
      if isAssumingParametersArray, let arrayValue = parameter.arrayValue {
        parametersArray.append(arrayValue)
      } else {
        isAssumingParametersArray = false
      }
    }

    return isAssumingParametersArray ? parametersArray : [parameters]
  }
}
