////
////  Extensions.swift
////  DynUISwift
////
////  Created by Daniel Pourhadi on 1/7/16.
////  Copyright © 2016 Daniel Pourhadi. All rights reserved.
////
//
//import Foundation
//
//extension NSObject {
//    private var propertyManager:ExtensionPropertyManager {
//        get {
//            let key = "_propertyManager_"
//            if let manager = objc_getAssociatedObject(self, key) as? ExtensionPropertyManager {
//                return manager
//            }
//            let manager = ExtensionPropertyManager()
//            objc_setAssociatedObject(self, key, manager, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//            return manager
//        }
//    }
//    
//    private func getProp<T:Style>(key:String) -> T? {
//        return self.propertyManager.properties[key.hashValue] as? T
//    }
//    
//    private func setProp<T:Style>(prop:T?,  _ key:String) {
//        self.propertyManager.properties[key.hashValue] = prop
//    }
//    
//    private func getAppliedStyles() -> [String:Style] {
//       return self.propertyManager.appliedStyles
//    }
//    
//    private func setAppliedStyles(styles:[String:Style]) {
//        self.propertyManager.appliedStyles = styles
//    }
//}
//
//private class ExtensionPropertyManager {
//    var properties = [Int:Any?]()
//    var appliedStyles = [String:Style]()
//}
//
//extension UIView:Styleable {
//    
//    private enum StyleableViewProperty: String {
//        case Background = "backgroundStyle"
//        case Border = "borderStyle"
//    }
//    
//    public var appliedStyles:[String:Style] {
//        get {
//           return self.getAppliedStyles()
//        }
//    }
//    
//    public var backgroundStyle:Fill? {
//        get {
//            return self.getProp(StyleableViewProperty.Background.rawValue)
//        }
//        set {
//            self.setProp(newValue, StyleableViewProperty.Background.rawValue)
//            self.applyBackgroundStyle(self, style: newValue)
//        }
//    }
//    
//    private func applyBackgroundStyle(object:UIView, style:Fill?) {
//        var styles = self.appliedStyles
//        styles[StyleableViewProperty.Background.rawValue] = style
//        self.setAppliedStyles(styles)
//    }
//}
