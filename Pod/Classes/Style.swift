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

public protocol StyleNaming {
    var styleName:String { get }
}

extension String: StyleNaming {
    public var styleName:String { return self }
}

public protocol Style {
    var name:StyleNaming { get }
}

public protocol DrawableStyle: Style, Renderable {}

public struct ViewStyle : DrawableStyle {
    public var name:StyleNaming
    
    public var backgroundStyle:Fill?
    
    public var borders:[Border] = []
    
    public var roundedCorners:UIRectCorner = []
    public var cornerRadius:CGFloat = 0
    
    public var innerShadow:Shadow?
    public var outerShadow:Shadow?
    
    public var renderAsynchronously = false
    
    public func render(var context:RenderContext) {
        if let rect = context.rect {
            let bez = UIBezierPath(roundedRect: rect, byRoundingCorners: self.roundedCorners, cornerRadii: CGSizeMake(self.cornerRadius, self.cornerRadius))
            bez.addClip()
            
            if let v = context.view {
                let mask = CAShapeLayer()
                mask.frame = v.bounds
                mask.path = bez.CGPath
                
                if self.renderAsynchronously {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        v.layer.mask = mask
                    })
                } else {
                    v.layer.mask = mask
                }
            }

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
    
    public init(name:StyleNaming) { self.name = name }
}

public struct TextStyle : Style {
    public var name:StyleNaming
    
    public var font:UIFont
    
    public var alignment:NSTextAlignment?
    public var color:Color?
    public var shadow:Shadow?
    
    public func asAttributes() -> [String:AnyObject] {
        var attributes = [String:AnyObject]()
        attributes[NSFontAttributeName] = self.font
        
        if let alignment = self.alignment {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = alignment
            attributes[NSParagraphStyleAttributeName] = paragraphStyle
        }
        
        if let color = self.color {
            attributes[NSForegroundColorAttributeName] = color.color
        }
        
        if let shadow = self.shadow {
            attributes[NSShadowAttributeName] = shadow.asNSShadow()
        }
        
        return attributes
    }
    
    public func asCSS() -> String { return "" }
    
    public func withSize(size:CGFloat) -> TextStyle {
        var new = self
        new.font = self.font.fontWithSize(size)
        return new
    }
    
    public init(_ name:StyleNaming, _ font:UIFont, _ color: Color = Color(UIColor.blackColor())) {
        self.font = font
        self.name = name
    }
}

public protocol StyleAttribute {}

public struct RenderContext {
    let rect:CGRect?
    var context:CGContextRef? { return UIGraphicsGetCurrentContext() }
    weak var view:UIView?

    var parameters:[String:AnyObject]?
    
    private var parentStyle:Style?

    init(rect:CGRect?, view:UIView?, parameters:[String:AnyObject]? = nil) {
        self.rect = rect
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
    
    public func asNSShadow() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowOffset = self.offset
        shadow.shadowColor = self.color.color
        shadow.shadowBlurRadius = self.radius
        return shadow
    }
    
    public init(radius:CGFloat, color:Color, offset:CGSize) {
        self.radius = radius
        self.color = color
        self.offset = offset
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
    var name:StyleNaming?
    var alpha:CGFloat = 1
    
    private var _color:UIColor?
    public var color:UIColor {
        if let color = _color {
            return color.colorWithAlphaComponent(self.alpha)
        }
        
        if let name = self.name {
            if let found = DynUI.colorForName(name) { return found.color.colorWithAlphaComponent(self.alpha) }
        }
        return UIColor()
    }
    
    public func render(context:RenderContext) {
        self.color.set()
        if let rect = context.rect, let c = context.context {
            CGContextFillRect(c, rect)
        }
    }
    
    public init(_ color:UIColor) {
        _color = color
    }
    
    public init(color:UIColor) {
        _color = color
    }
    
    public init(name:StyleNaming) {
        self.name = name
    }
    
    public init(_ name:StyleNaming, alpha:CGFloat = 1) {
        self.name = name
        self.alpha = alpha
    }
    
    public init(withHexAsName:String) {
        _color = UIColor(rgba: withHexAsName)
        self.name = withHexAsName
    }
    
}

extension Color:AutoSerializable {
    public init?(withValuesForKeys:[String:Serializable]) {
        if let color = withValuesForKeys["color"] as? UIColor {
            _color = color
        } else { _color = nil }
        self.name = withValuesForKeys["name"] as? StyleNaming
    }
}

extension UIColor {
    public func dyn_color() -> Color {
        return Color(color: self)
    }
}

public struct Gradient:FillStyleAttribute {
    var name:StyleNaming?
    
    let colors:[Color]
    let locations:[CGFloat]
    let startPoint:CGPoint
    let endPoint:CGPoint

    public init(colors:[Color], locations:[CGFloat], startPoint:CGPoint, endPoint:CGPoint) {
        self.colors = colors
        self.locations = locations
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
    
    public func render(context:RenderContext) {
        log("gradient render")
        if let c = context.context, r = context.rect {
            CGContextSaveGState(c)
            CGContextTranslateCTM(c, 0, r.size.height)
            CGContextScaleCTM(c, 1.0, -1.0)
            let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), self.colors.map { $0.color.CGColor }, self.locations)
            
            let start = CGPointMake(self.startPoint.x * r.size.width, self.startPoint.y * r.size.height)
            let end = CGPointMake(self.endPoint.x * r.size.width, self.endPoint.y * r.size.height)
            CGContextDrawLinearGradient(c, gradient, start, end, CGGradientDrawingOptions.DrawsAfterEndLocation)
            CGContextRestoreGState(c)
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