//
//  Style.swift
//  DynUISwift
//
//  Created by Daniel Pourhadi on 1/7/16.
//  Copyright © 2016 Daniel Pourhadi. All rights reserved.
//

import Foundation
import SuperSerial
import QuartzCore
import CoreGraphics

public protocol Style {
    var name:String { get }
}

public protocol DrawableStyle: Style, Renderable {}

public struct ViewStyle : DrawableStyle {
    public var name:String
    
    var backgroundStyle:Fill?
    
    var borders:[Border]?
    
    var innerShadow:Shadow?
    var outerShadow:Shadow?
    
    var renderAsynchronously = false
    
    public func render(context:RenderContext) {}
    public var renderPriority = 0
    public var prepFunction:RenderPrepFunction? = nil
}

public struct TextStyle : Style {
    public var attributes:TextStyleAttribute
    public var name:String
}

public protocol StyleAttribute {}

public struct RenderContext {
    let rect:CGRect?
    let context:CGContextRef?
    weak var view:UIView?

    var parameters:[String:AnyObject]?
}

public typealias RenderPrepFunction = ((context:RenderContext)->Void)
public protocol Renderable {
    var renderPriority:Int { get }
    var prepFunction:RenderPrepFunction? { get }
    func render(context:RenderContext)
}

public protocol DrawingStyleAttribute:StyleAttribute, Renderable {}

public struct Fill: DrawingStyleAttribute {
    public var renderPriority = 1
    public var prepFunction:RenderPrepFunction? = nil
    let fillStyle:FillStyleAttribute
    public func render(context:RenderContext) { self.fillStyle.render(context) }
    
    public init(fillStyle:FillStyleAttribute) {
        self.fillStyle = fillStyle
    }
}

public struct Border:DrawingStyleAttribute {
    public enum BorderType {
        case OuterStroke
        case InnerTop
        case InnerLeft
        case InnerBottom
        case InnerRight
    }
    
    public var renderPriority = 0
    let width:CGFloat
    let color:Color
    let borderType:BorderType
    
    public init(width:CGFloat, color:Color, borderType:BorderType) {
        self.width = width
        self.color = color
        self.borderType = borderType
    }
    
    public func render(context:RenderContext) {
    }
    
    public var prepFunction:RenderPrepFunction? = nil
}

public struct Shadow:DrawingStyleAttribute {
    public var renderPriority = 0

    let radius:CGFloat
    let color:Color
    let offset:CGSize
    
    public func render(context:RenderContext) {
        
    }
    public var prepFunction:RenderPrepFunction? = nil
}

extension Shadow:AutoSerializable {
    public init?(withValuesForKeys:[String:Serializable]) {
        self.radius = withValuesForKeys["radius"] as! CGFloat
        self.color = withValuesForKeys["color"] as! Color
        self.offset = withValuesForKeys["offset"] as! CGSize
    }
}

public struct TextStyleAttribute:StyleAttribute {}

public struct InvalidStyle:StyleAttribute {}

public protocol FillStyleAttribute: Renderable {}

public struct Color:FillStyleAttribute {
    var name:String?
    
    var color:UIColor
    public func render(context:RenderContext) {
        self.color.set()
        if let rect = context.rect, let c = context.context {
            CGContextFillRect(c, rect)
        }
    }
    
    public init(color:UIColor) {
        self.color = color
    }
    public var prepFunction:RenderPrepFunction? = nil
    public var renderPriority = 0
}

extension Color:AutoSerializable {
    public init?(withValuesForKeys:[String:Serializable]) {
        if let color = withValuesForKeys["color"] as? UIColor {
            self.color = color
        } else { self.color = UIColor() }
        self.name = withValuesForKeys["name"] as? String
    }
}

public struct Gradient:FillStyleAttribute {
    var name:String?
    
    let colors:[Color]
    let locations:[CGFloat]
    let startPoint:CGPoint
    let endPoint:CGPoint

    public func render(context:RenderContext) {
        if let c = context.context {
            let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), self.colors.map { $0.color.CGColor }, self.locations)
            CGContextDrawLinearGradient(c, gradient, self.startPoint, self.endPoint, CGGradientDrawingOptions.DrawsAfterEndLocation)
        }
    }
    public var prepFunction:RenderPrepFunction? = nil
    public var renderPriority = 0
}

extension Gradient:AutoSerializable {
    public init?(withValuesForKeys: [String : Serializable]) {
        self.name = withValuesForKeys["name"] as? String
        self.colors = withValuesForKeys["colors"] as! [Color]
        self.locations = withValuesForKeys["locations"] as! [CGFloat]
        self.startPoint = withValuesForKeys["startPoint"] as! CGPoint
        self.endPoint = withValuesForKeys["endPoint"] as! CGPoint
    }
}