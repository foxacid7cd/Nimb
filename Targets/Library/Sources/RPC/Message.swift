//
//  Message.swift
//  Library
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public enum Message {
  case request(id: UInt, model: Request)
  case response(id: UInt, model: Response)
  case notification(Notification)
}
