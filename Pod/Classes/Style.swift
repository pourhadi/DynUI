//
//  Style.swift
//  DynUISwift
//
//  Created by Daniel Pourhadi on 1/7/16.
//  Copyright © 2016 Daniel Pourhadi. All rights reserved.
//

import Foundation

protocol Style {
    var name:String { get }
}

public protocol StyleAttribute {}

public protocol DrawingStyleAttribute:StyleAttribute {
    func draw(inRect:CGRect, inContext:CGContextRef)
}

public enum Fill:DrawingStyleAttribute {
    case Solid(ColorStyleAttribute)
    case Gradient(colors:[ColorStyleAttribute], locations:[CGPoint])
    case Blur(UIBlurEffectStyle)
    
    public func draw(inRect: CGRect, inContext:CGContextRef) {}
}

//extension Fill:Serializable {
//    func serialize() -> [String : String] {
//        switch self {
//        case .Solid(let attr): return "solid:\(attr.serialize())"
//        }
//    }
//    
//    init(fromDictionary: [String : String]) {
//        
//    }
//}

public struct Border:DrawingStyleAttribute {
    let width:CGFloat
    let color:ColorStyleAttribute
    
    let roundedCorners:UIRectCorner
    let cornerRadius:CGFloat
    
    public func draw(inRect: CGRect, inContext:CGContextRef) {}
}

public struct Shadow:DrawingStyleAttribute {
    let radius:CGFloat
    let color:ColorStyleAttribute
    let offset:CGSize
    
    public func draw(inRect: CGRect, inContext:CGContextRef) {}
}

public struct Text:StyleAttribute {}

public struct InvalidStyle:StyleAttribute {}

//
// *****
//

public struct ColorStyleAttribute:DrawingStyleAttribute {
    var name:String?
    
    var color:UIColor
    public func draw(inRect: CGRect, inContext:CGContextRef) {}
}

extension ColorStyleAttribute:Serializable {
    enum Keys:String {
        case name
        case color
    }
    
    func serialize() -> Serialized {
        var dict = [String:Serialized]()
        if let name = self.name {
            dict[Keys.name.rawValue] = Serialized.Str(name)
        }
        
        dict[Keys.color.rawValue] = self.color.serialize()
        return Serialized.Dict(dict)
    }
    
    static func fromSerialized(serialized: Serialized) -> ColorStyleAttribute? {
        var name:String?
        var color:UIColor?
        
        switch serialized {
        case .Dict(let dict):
            if let serializedName = dict[Keys.name.rawValue] {
                name = String.fromSerialized(serializedName)
            }
            
            if let serializedColor = dict[Keys.color.rawValue] {
                color = UIColor.fromSerialized(serializedColor)
            }
            return ColorStyleAttribute(name: name, color: color!)
        default: return nil
        }
    }
}

//
// *****
//

public struct GradientStyleAttribute:DrawingStyleAttribute {
    var name:String?
    
    let colors:[ColorStyleAttribute]
    let locations:[CGPoint]

    public func draw(inRect: CGRect, inContext:CGContextRef) {}
}

extension GradientStyleAttribute:Serializable {
    enum Keys:String {
        case name
        case colors
        case locations
    }
    
    func serialize() -> Serialized {
        var dict = [String:Serialized]()
        if let name = self.name {
            dict[Keys.name.rawValue] = name.serialize()
        }
        
        dict[Keys.colors.rawValue] = self.colors.serialize()
        dict[Keys.locations.rawValue] = Serialized.Array(self.locations.map { $0.serialize() })
        return Serialized.Dict(dict)
    }
    static func fromSerialized(serialized: Serialized) -> GradientStyleAttribute? {
        var name:String?
        var colors = [ColorStyleAttribute]()
        var locations = [CGPoint]()
        switch serialized {
        case .Dict(let dict):
            if let nameval = dict[Keys.name.rawValue] { name = String.fromSerialized(nameval) }
            if let colorval = dict[Keys.colors.rawValue] {
                colors = [ColorStyleAttribute].fromSerialized(colorval)!
            }
            if let locval = dict[Keys.locations.rawValue] {
                locations = [CGPoint].fromSerialized(locval)!
            }
            
            return GradientStyleAttribute(name: name, colors: colors, locations: locations)
        default: return nil
        }
    }
    
}