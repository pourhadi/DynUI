//
//  Manager.swift
//  Pods
//
//  Created by Daniel Pourhadi on 1/23/16.
//
//

import Foundation

internal func log(logMessage: String, functionName: String = __FUNCTION__) {
    print("\(functionName): \(logMessage)")
}

public class DynUI {
    
    public static var drawableStyles = [DrawableStyle]()
    public class func drawableStyleForName(name:String) -> DrawableStyle? {
        if let index = self.drawableStyles.indexOf({ $0.name == name }) {
            return self.drawableStyles[index]
        }
        return nil
    }
    
    public static var textStyles = [TextStyle]()
    public class func textStyleForName(value:(name:String, size:CGFloat)) -> TextStyle? {
        if let index = self.textStyles.indexOf({ $0.name == value.name }) {
            return self.textStyles[index].withSize(value.size)
        }
        return nil
    }
    
    internal static var renderQueue = dispatch_queue_create("com.pourhadi.DynUI.Rendering", DISPATCH_QUEUE_SERIAL)
}