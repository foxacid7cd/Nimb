// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation
import NvimAPI
import SwiftSyntax
import SwiftSyntaxBuilder

struct NeovimAPIMetadata {
  struct Function {
    var name = ""
    var parameters = [Parameter]()
    var returnType = ""
    var method = false
    var since = 0
    var deprecatedSince: Int?
  }

  struct Parameter {
    var name: String
    var type: String
  }

  var functions = [Function]()
}

extension NeovimAPIMetadata {
  init(map: Map) {
    var model = NeovimAPIMetadata()

    for (key, value) in map {
      switch key as! String {
      case "functions":
        var functions = [Function]()

        let array = value as! [Map]

        for value in array {
          var function = Function()

          for (functionKey, functionValue) in value {
            switch functionKey as! String {
            case "name":
              function.name = functionValue as! String

            case "parameters":
              var parameters = [Parameter]()

              for parameterData in functionValue as! [[String]] {
                parameters.append(
                  .init(
                    name: parameterData[1],
                    type: parameterData[0]
                  )
                )
              }

              function.parameters = parameters

            case "return_type":
              function.returnType = functionValue as! String

            case "method":
              function.method = functionValue as! Bool

            case "since":
              function.since = functionValue as! Int

            case "deprecated_since":
              function.deprecatedSince = functionValue as? Int

            default:
              fatalError("Unknown key \(String(describing: functionKey))")
            }
          }

          functions.append(function)
        }

        model.functions = functions

      default:
        continue
      }
    }

    self = model
  }
}
