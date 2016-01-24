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

public struct ViewDrawingStyle : Style, Renderable {
    public var name:String
    
    var backgroundStyle:Fill?
    
    var borders:[Border]?
    
    var innerShadow:Shadow?
    var outerShadow:Shadow?
    
    public func render(context:RenderContext) {}
    public var renderPriority = 0
    public var prepFunction:RenderPrepFunction? = nil
}

public struct DrawingStyle : Style, Renderable {
    public var name:String
    public var clipsToBounds:Bool = false
    public var rendersAsynchronously:Bool = false
    public let attributes:[DrawingStyleAttribute]
    
    public func render(context:RenderContext) {
        for attr in self.attributes.sort({ (attrL, attrR) -> Bool in
            return attrL.renderPriority > attrR.renderPriority
        }){
            attr.render(context)
        }
    }
    
    public var prepFunction:RenderPrepFunction? {
        return { context in
            for attr in self.attributes {
                if let function = attr.prepFunction {
                    function(context: context)
                }
            }
        }
    }
    
    public init(name:String, attributes:[DrawingStyleAttribute]) {
        self.name = name
        self.attributes = attributes
    }
    public var renderPriority = 0
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
    
    var clipsToBounds = false
    var isAsynchronous = false
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
//        if let v = context.view, rect = context.rect {
//            let image = UIImage.drawImage(rect.insetBy(dx: -self.width/2, dy: -self.width/2).size, withBlock: { (drawRect) -> Void in
//                let b = UIBezierPath(roundedRect: rect.centeredIn(drawRect), byRoundingCorners: self.roundedCorners, cornerRadii: CGSizeMake(self.cornerRadius, self.cornerRadius))
//                let c = UIGraphicsGetCurrentContext()
//                CGContextSetLineWidth(c, self.width)
//                CGContextSetStrokeColorWithColor(c, self.color.color.CGColor)
//                CGContextAddPath(c, b.CGPath)
//                CGContextStrokePath(c)
//            })
//            if context.isAsynchronous {
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    v.dyn_overlayView.image = image
//                    v.dyn_overlayView.contentMode = .Center
//                })
//            } else {
//                v.dyn_overlayView.image = image
//                v.dyn_overlayView.contentMode = .Center
//            }
//        } else if let c = context.context, rect = context.rect {
//            let b = UIBezierPath(roundedRect: rect.insetBy(dx: self.width/2, dy: self.width/2), byRoundingCorners: self.roundedCorners, cornerRadii: CGSizeMake(self.cornerRadius, self.cornerRadius))
//            CGContextSetLineWidth(c, self.width)
//            CGContextSetStrokeColorWithColor(c, self.color.color.CGColor)
//            CGContextAddPath(c, b.CGPath)
//            CGContextStrokePath(c)
//        }
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