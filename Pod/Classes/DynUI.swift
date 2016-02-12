//
//  Manager.swift
//  Pods
//
//  Created by Daniel Pourhadi on 1/23/16.
//
//

import Foundation
import SuperSerial

internal func log(logMessage: String = "", _ functionName: String = __FUNCTION__) {
    if DynUI.loggingEnabled { print("\(functionName): \(logMessage)") }
}

public class DynUI {
    
    private static var prepared = false
    public class func prepare() {
        guard !prepared else { return }
        prepared = true
        SuperSerial.addSerializableTypes([ViewStyle.self, Color.self, Gradient.self, Fill.self, Shadow.self, Border.self])
    }
    
    public static var loggingEnabled:Bool = false
    
    public class func initialize(colors:[Color] = [], drawableStyles:[DrawableStyle] = [], textStyles:[TextStyle] = []) {
        prepare()
        _colors = colors
        _drawableStyles = drawableStyles
        _textStyles = textStyles
    }
    
    private static var _drawableStyles = [DrawableStyle]()
    public static var drawableStyles:[DrawableStyle] {
        return _drawableStyles
    }
    
    public class func drawableStyleForName(name:StyleNaming) -> DrawableStyle? {
        if let index = self.drawableStyles.indexOf({ $0.name.styleName == name.styleName }) {
            return self.drawableStyles[index]
        }
        return nil
    }
    
    private static var _textStyles = [TextStyle]()
    public static var textStyles:[TextStyle] {
        return _textStyles
    }
    
    public class func textStyleForName(value:(name:StyleNaming, size:CGFloat)) -> TextStyle? {
        if let index = self.textStyles.indexOf({ $0.name.styleName == value.name.styleName }) {
            return self.textStyles[index].withSize(value.size)
        }
        return nil
    }
    
    public class func textStyleForName(name:StyleNaming) -> TextStyle? {
        if let index = self.textStyles.indexOf({ $0.name.styleName == name.styleName }) {
            return self.textStyles[index]
        }
        return nil
    }
    
    private static var _colors = [Color]()
    public static var colors:[Color] { return _colors }
    
    public class func colorForName(name:StyleNaming) -> Color? {
        if let index = self.colors.indexOf({ $0.name!.styleName == name.styleName }) {
            return self.colors[index]
        }
        return nil
    }
    
    internal static var renderQueue = dispatch_queue_create("com.pourhadi.DynUI.Rendering", DISPATCH_QUEUE_SERIAL)
}