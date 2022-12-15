// Copyright © 2022 foxacid7cd. All rights reserved.

public enum UIEventDecodingError: Error {
  case invalidName(String)
  case encodedValueIsNotArray(details: String)
  case invalidEncodedValue(details: String)
}
