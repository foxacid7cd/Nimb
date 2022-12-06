//
//  File.swift
//  
//
//  Created by Yevhenii Matviienko on 06.12.2022.
//

public enum UIEventDecodingFailed: Error {
  case unknownName(String)
  case encodedValueIsNotArray(description: String)
  case invalidEncodedValue(description: String)
}
