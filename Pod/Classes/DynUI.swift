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
    
    public static var drawingStyles = [DrawingStyle]()
    
    public class func drawingStyleForName(name:String) -> DrawingStyle? {
        if let index = self.drawingStyles.indexOf({ $0.name == name }) {
            return self.drawingStyles[index]
        }
        return nil
    }
    
    internal static var renderQueue = dispatch_queue_create("com.pourhadi.DynUI.Rendering", DISPATCH_QUEUE_SERIAL)
}