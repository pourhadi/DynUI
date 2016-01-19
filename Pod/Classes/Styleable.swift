//
//  Styleable.swift
//  DynUISwift
//
//  Created by Daniel Pourhadi on 1/7/16.
//  Copyright © 2016 Daniel Pourhadi. All rights reserved.
//

import Foundation


//public struct StyleableProperty<S:Style>: CustomStringConvertible, Hashable {
//    var style:S? {
//        didSet {
//            if let _ = self.style {
//                self.applyBlock(property: self)
//            }
//        }
//    }
//    
//    internal let id:String
//    
//    public var hashValue:Int { return self.id.hashValue }
//    public var description:String { return "\(S.self)" }
//    
//    internal let applyBlock:(property:StyleableProperty)->Void
//    
//    init(_ block:(property:StyleableProperty)->Void) {
//        self.id = NSUUID().UUIDString
//        self.applyBlock = block
//    }
//}
//
//public func ==<T>(l:StyleableProperty<T>, r:StyleableProperty<T>) -> Bool {
//    return l.id == r.id
//}

public protocol Styleable:class {
}

public protocol StyleableView : Styleable {}
public protocol StyleableControl : StyleableView {}
public protocol StyleableText : Styleable {}