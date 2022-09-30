//
//  APIInfo.swift
//  neogen
//
//  Created by Yevhenii Matviienko on 28.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

struct APIInfo: Decodable {
  var errorTypes: [String: ErrorType]
  var uiOptions: [String]
  var functions: [Function]
  var types: [String: `Type`]
  var uiEvents: [UIEvent]
  
  struct ErrorType: Decodable {
    var id: Int
  }
  
  enum CodingKeys: String, CodingKey {
    case errorTypes = "error_types"
    case uiOptions = "ui_options"
    case functions
    case types
    case uiEvents = "ui_events"
  }
  
  struct Function: Decodable {
    var deprecatedSince: Int?
    var method: Bool
    var name: String
    var parameters: [Parameter]
    var returnType: String
    var since: Int
    
    enum CodingKeys: String, CodingKey {
      case deprecatedSince = "deprecated_since"
      case method
      case name
      case parameters
      case returnType = "return_type"
      case since
    }
  }
  
  struct `Type`: Decodable {
    var id: Int
    var prefix: String
  }
  
  struct UIEvent: Decodable {
    var name: String
    var parameters: [Parameter]
    var since: Int
  }
  
  struct Version: Decodable {
    var apiCompatible: Int
    var apiLevel: Int
    var apiPrerelease: Bool
    var major: Int
    var minor: Int
    var patch: Int
    var prerelease: Bool
    
    enum CodingKeys: String, CodingKey {
      case apiCompatible = "api_compatible"
      case apiLevel = "api_level"
      case apiPrerelease = "api_prerelease"
      case major
      case minor
      case patch
      case prerelease
    }
  }
  
  struct Parameter: Decodable {
    var type: String
    var name: String
   
    init(type: String, name: String) {
      self.type = type
      self.name = name
    }
    
    init(from decoder: Decoder) throws {
      var container: UnkeyedDecodingContainer = try decoder.unkeyedContainer()
      self.type = try container.decode(String.self)
      self.name = try container.decode(String.self)
    }
  }
}
