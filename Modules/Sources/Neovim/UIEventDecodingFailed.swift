// Copyright © 2022 foxacid7cd. All rights reserved.

public enum UIEventDecodingFailed: Error {
  case unknownName(String)
  case encodedValueIsNotArray(description: String)
  case invalidEncodedValue(description: String)
}
