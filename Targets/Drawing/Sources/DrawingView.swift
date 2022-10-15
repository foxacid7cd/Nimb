//
//  DrawingView.swift
//  Drawing
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Library
import SwiftUI

public class DrawingView: NSView, ObservableObject {
  private var ctFramesetter: CTFramesetter
  private var ctFrame: CTFrame
  
  override public init(frame frameRect: NSRect) {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .natural
    paragraphStyle.lineBreakMode = .byWordWrapping
    
    let font = NSFont.monospacedSystemFont(ofSize: 24, weight: .regular)
    
    let textAttributes = [
      NSAttributedString.Key.paragraphStyle: paragraphStyle,
      NSAttributedString.Key.font: font,
      NSAttributedString.Key.foregroundColor: NSColor.white
    ]
    let attributedString = CFAttributedStringCreate(nil, "Hello World!" as CFString, textAttributes as CFDictionary)!
    
    let ctFramesetter = CTFramesetterCreateWithAttributedString(attributedString)
    self.ctFramesetter = ctFramesetter
    
    let ctFrame = CTFramesetterCreateFrame(ctFramesetter, .init(location: 0, length: "Hello World!".count), .init(rect: .init(x: 50, y: -50, width: 300, height: 300), transform: nil), nil)
    self.ctFrame = ctFrame
    
    super.init(frame: frameRect)
    
    setNeedsDisplay(bounds)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override public func draw(_ dirtyRect: NSRect) {
    guard let context = NSGraphicsContext.current else {
      "missing current graphics context".fail().failAssertion()
      return
    }
    context.saveGraphicsState()
    defer { context.restoreGraphicsState() }
    
    CTFrameDraw(ctFrame, context.cgContext)
  }
}
