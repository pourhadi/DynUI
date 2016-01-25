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
    
    var borders:[Border] = []
    
    var roundedCorners:UIRectCorner = []
    var cornerRadius:CGFloat = 0
    
    var innerShadow:Shadow?
    var outerShadow:Shadow?
    
    var renderAsynchronously = false
    
    public func render(var context:RenderContext) {
        if let rect = context.rect {
            let bez = UIBezierPath(roundedRect: rect, byRoundingCorners: self.roundedCorners, cornerRadii: CGSizeMake(self.cornerRadius, self.cornerRadius))
            bez.addClip()
            
            context.setParentStyle(self)
            
            if let bg = self.backgroundStyle {
                bg.render(context)
            }
            
            for border in borders {
                border.render(context)
            }
            
            if let innerShadow = self.innerShadow {
                innerShadow.render(context)
            }
            
            if let outerShadow = self.outerShadow {
                outerShadow.render(context)
            }
        }
    }
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
    
    private var parentStyle:Style?

    init(rect:CGRect?, context:CGContextRef?, view:UIView?, parameters:[String:AnyObject]? = nil) {
        self.rect = rect
        self.context = context
        self.view = view
        self.parameters = parameters
    }
    
    private mutating func setParentStyle<T:Style>(parentStyle:T) {
        self.parentStyle = parentStyle
    }
    
    private func getParentStyle<T:Style>() -> T? {
        return self.parentStyle as? T
    }
}

public typealias RenderPrepFunction = ((context:RenderContext)->Void)
public protocol Renderable {
    func render(context:RenderContext)
}

public protocol DrawingStyleAttribute:StyleAttribute, Renderable {}

public struct Fill: DrawingStyleAttribute {
    let fillStyle:FillStyleAttribute
    public func render(context:RenderContext) { self.fillStyle.render(context) }
    
    public init(fillStyle:FillStyleAttribute) {
        self.fillStyle = fillStyle
    }
}

public struct Border:DrawingStyleAttribute {
    public enum BorderType {
        case OuterStroke
        case InnerStroke
        case InnerTop
        case InnerLeft
        case InnerBottom
        case InnerRight
    }
    
    let width:CGFloat
    let color:Color
    let borderType:BorderType
    
    var blendMode:CGBlendMode = .Normal
    
    public init(width:CGFloat, color:Color, borderType:BorderType) {
        self.width = width
        self.color = color
        self.borderType = borderType
    }
    
    public func render(context:RenderContext) {
        switch self.borderType {
        case .OuterStroke: self.addOuterStroke(context)
            break
        default: self.drawInnerStroke(context)
            break
        }
    }
    
    private func addOuterStroke(context:RenderContext) {
        if let v = context.view, style = context.getParentStyle() as ViewStyle?, rect = context.rect {
            let image = UIImage.drawImage(rect.insetBy(dx: -self.width/2, dy: -self.width/2).size, withBlock: { (drawRect) -> Void in
                let b = UIBezierPath(roundedRect: rect.centeredIn(drawRect), byRoundingCorners: style.roundedCorners, cornerRadii: CGSizeMake(style.cornerRadius, style.cornerRadius))
                let c = UIGraphicsGetCurrentContext()
                CGContextSetLineWidth(c, self.width)
                CGContextSetStrokeColorWithColor(c, self.color.color.CGColor)
                CGContextAddPath(c, b.CGPath)
                CGContextStrokePath(c)
            })
            if style.renderAsynchronously {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    v.dyn_overlayView.image = image
                    v.dyn_overlayView.contentMode = .Center
                })
            } else {
                v.dyn_overlayView.image = image
                v.dyn_overlayView.contentMode = .Center
            }
        }
    }
    
    private func drawInnerStroke(context:RenderContext) {
        if let rect = context.rect, style = context.getParentStyle() as ViewStyle? {
            func renderInnerBorder(path:UIBezierPath, shadowOffset:CGSize) {
                guard let c = context.context else { return }
                let shadowBlurRadius:CGFloat = 0
            
                var rectangle2BorderRect = CGRectInset(path.bounds, -shadowBlurRadius, -shadowBlurRadius)
                rectangle2BorderRect = CGRectOffset(rectangle2BorderRect, -shadowOffset.width, -shadowOffset.height)
                rectangle2BorderRect = CGRectInset(CGRectUnion(rectangle2BorderRect, path.bounds), -1, -1)

                let rectangle2NegativePath = UIBezierPath(rect: rectangle2BorderRect)
                rectangle2NegativePath.miterLimit = -10
                
                rectangle2NegativePath.appendPath(path)
                rectangle2NegativePath.usesEvenOddFillRule = true
                
                CGContextSaveGState(c)
                CGContextSetBlendMode(c, self.blendMode)
                let xOffset = shadowOffset.width + round(rectangle2BorderRect.size.width)
                let yOffset = shadowOffset.height
                CGContextSetShadowWithColor(c, CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),shadowBlurRadius, self.color.color.CGColor)
                
                path.addClip()
                let transform = CGAffineTransformMakeTranslation(-round(rectangle2BorderRect.size.width), 0)
                rectangle2NegativePath.applyTransform(transform)
                UIColor.grayColor().setFill()
                rectangle2NegativePath.fill()
                CGContextRestoreGState(c)
            }


            self.color.color.set()
            let bez:UIBezierPath
            var offset:CGSize = CGSizeZero

            switch self.borderType {
            case .InnerStroke:
                bez = UIBezierPath(roundedRect: rect.insetBy(dx: self.width/2, dy: self.width/2), byRoundingCorners: style.roundedCorners, cornerRadii: CGSizeMake(style.cornerRadius, style.cornerRadius))
                bez.lineWidth = self.width
                bez.stroke()
            default:
                switch self.borderType {
                case .InnerTop:
                    offset = CGSizeMake(0, self.width)
                case .InnerLeft:
                    offset = CGSizeMake(self.width, 0)
                case .InnerBottom:
                    offset = CGSizeMake(0, -self.width)
                case .InnerRight:
                    offset = CGSizeMake(-self.width, 0)
                default:
                    break
                }
                
                bez = UIBezierPath(roundedRect: rect, byRoundingCorners: style.roundedCorners, cornerRadii: CGSizeMake(style.cornerRadius, style.cornerRadius))
                renderInnerBorder(bez, shadowOffset: offset)
            }
        }
    }
    
}

public struct Shadow:DrawingStyleAttribute {

    let radius:CGFloat
    let color:Color
    let offset:CGSize
    
    public func render(context:RenderContext) {
        
    }
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