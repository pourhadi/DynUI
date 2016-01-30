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
    private var savedStyle:ViewStyle? {
        if self.originality == .Saved {
            return DynUI.drawableStyleForName(self.name) as? ViewStyle
        }
        return nil
    }
    
    private let originality:StyleOriginality
    public var name:StyleNaming
    
    private var _backgroundStyle:Fill?
    public var backgroundStyle:Fill? {
        set { _backgroundStyle = newValue }
        get {
            if let style = _backgroundStyle { return style }
            else { if let style = self.savedStyle { return style.backgroundStyle } else { return nil } }
        }}
    
    private var _borders:[Border]?
    public var borders:[Border] {
            set { _borders = newValue }
            get {
                if let borders = _borders { return borders }
                else { if let style = self.savedStyle { return style.borders } else { return [] } }
            }}
    
    private var _roundedCorners:UIRectCorner?
    public var roundedCorners:UIRectCorner {
        set { _roundedCorners = newValue }
        get {
            if let corners = _roundedCorners { return corners }
            else { if let style = self.savedStyle { return style.roundedCorners } else { return [] } }
        }}
    
    private var _cornerRadius:CGFloat?
    public var cornerRadius:CGFloat {
        set { _cornerRadius = newValue }
        get {
            if let radius = _cornerRadius { return radius }
            else { if let style = self.savedStyle { return style.cornerRadius } else { return 0 } }
        }}
    
    public var innerShadow:Shadow?
    public var outerShadow:Shadow?
    
    public var mask:Bool = false
    
    public var renderInset:UIEdgeInsets = UIEdgeInsetsZero
    
    public func render(var context:RenderContext) {
        if let rect = context.rect {
            let bez:UIBezierPath
            
            if let path = context.path {
                bez = path
            } else {
                var newRect = rect
                newRect.origin.x += self.renderInset.left
                newRect.size.width -= self.renderInset.left
                newRect.origin.y += self.renderInset.top
                newRect.size.height -= self.renderInset.top
                newRect.size.width -= self.renderInset.right
                newRect.size.height -= self.renderInset.bottom
                context.rect = newRect
                bez = UIBezierPath(roundedRect: newRect, byRoundingCorners: self.roundedCorners, cornerRadii: CGSizeMake(self.cornerRadius, self.cornerRadius))
            }
            
            bez.addClip()
            
            if let v = context.view where self.mask == true {
                let mask = CAShapeLayer()
                mask.frame = v.bounds
                mask.path = bez.CGPath
                v.layer.mask = mask
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
    
    public init(name:StyleNaming) {
        self.init(newWithName:name)
    }
    
    public init(newWithName:StyleNaming) {
        self.originality = .New
        self.name = newWithName
    }
    
    public init(savedWithName:StyleNaming) {
        self.originality = .Saved
        self.name = savedWithName
    }
}

extension ViewStyle {
    public func withBorders(borders:[Border]) -> ViewStyle {
        var new = self
        new.borders = borders
        return new
    }
}

public struct ButtonStyle: DrawableStyle {
    public init(name:StyleNaming) { self.name = name }
    public var name:StyleNaming

    public var viewStyle:StyleNaming?
    public var highlightedViewStyle:StyleNaming?
    
    public var textStyle:TextStyle?
    public var highlightedTextStyle:TextStyle?
    
    public func render(context:RenderContext) { }
}

internal enum StyleOriginality:Int {
    case New
    case Saved
}

public struct TextStyle : Style {
    internal let originality:StyleOriginality
    public var name:StyleNaming
    
    private var savedStyle:TextStyle? {
        if self.originality == .Saved {
            return DynUI.textStyleForName(self.name)
        }
        return nil
    }
    
    private var _font:UIFont?
    public var font:UIFont {
        set {
            self._font = newValue
        }
        get {
            if let font = self._font {
                if self._size > 0 {
                    return font.fontWithSize(self._size)
                } else { return font }
            }
            if let style = self.savedStyle {
                if self._size > 0 {
                    return style.font.fontWithSize(self._size)
                } else { return style.font }
            }
            return UIFont()
        }
    }
    
    private var _alignment:NSTextAlignment?
    public var alignment:NSTextAlignment? {
        set {
            self._alignment = newValue
        }
        get {
            if let alignment = self._alignment { return alignment }
            if let style = self.savedStyle {
                return style.alignment
            }
            return nil
        }
    }
    
    private var _color:Color?
    public var color:Color? {
        set {
            self._color = newValue
        }
        get {
            if let color = self._color { return color }
            if let style = self.savedStyle {
                return style.color
            }
            return nil
        }
    }
    
    private var _shadow:Shadow?
    public var shadow:Shadow? {
        set {
            self._shadow = newValue
        }
        get {
            if let shadow = self._shadow { return shadow }
            if let style = self.savedStyle {
                return style.shadow
            }
            return nil
        }
    }
    
    private var _highlightedTextColor:Color?
    public var highlightedTextColor:Color? {
        set {
            self._highlightedTextColor = newValue
        }
        get {
            if let color = self._highlightedTextColor { return color }
            if let style = self.savedStyle {
                return style.highlightedTextColor
            }
            return nil
        }
    }
    
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
    
    public init(newStyleNamed name:StyleNaming, _ font:UIFont, _ color: Color = Color(UIColor.blackColor())) {
        self.originality = .New
        self._font = font
        self._size = font.pointSize
        self.name = name
        self.color = color
    }
    
    private var _size:CGFloat = 0
    public init(_ savedStyleNamed:StyleNaming, _ size:CGFloat = 0) {
        self.originality = .Saved
        self.name = savedStyleNamed
        self._size = size
    }
}

extension TextStyle {
    public func withSize(size:CGFloat) -> TextStyle {
        var new = self
        new._size = size
        return new
    }
    
    public func withColor(color:Color) -> TextStyle {
        var new = self
        new.color = color
        return new
    }
    
    public func withShadow(shadow:Shadow) -> TextStyle {
        var new = self
        new.shadow = shadow
        return new
    }
    
    public func withAlignment(alignment:NSTextAlignment) -> TextStyle {
        var new = self
        new.alignment = alignment
        return new
    }
    
    public func withHighlightedTextColor(color:Color) -> TextStyle {
        var new = self
        new.highlightedTextColor = color
        return new
    }
}

public protocol StyleAttribute {}

public struct RenderContext {
    var rect:CGRect?
    var context:CGContextRef? { return UIGraphicsGetCurrentContext() }
    weak var view:UIView?

    var path:UIBezierPath?
    
    var parameters:[String:AnyObject]?
    
    private var parentStyle:Style?

    init(rect:CGRect?, view:UIView?, parameters:[String:AnyObject]? = nil) {
        self.rect = rect
        self.view = view
        self.parameters = parameters
    }
    
    init(path:UIBezierPath, view:UIView?) {
        self.path = path
        self.rect = path.bounds
        self.view = view
        self.parameters = nil
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
                let b:UIBezierPath
                
                if let p = context.path {
                    b = p
                } else {
                    b = UIBezierPath(roundedRect: rect.centeredIn(drawRect), byRoundingCorners: style.roundedCorners, cornerRadii: CGSizeMake(style.cornerRadius, style.cornerRadius))
                }
                let c = UIGraphicsGetCurrentContext()
                CGContextSetLineWidth(c, self.width)
                CGContextSetStrokeColorWithColor(c, self.color.color.CGColor)
                CGContextAddPath(c, b.CGPath)
                CGContextStrokePath(c)
            })
            v.dyn_overlayView.image = image
            v.dyn_overlayView.contentMode = .Center
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
                if let p = context.path {
                    bez = p
                } else {
                    bez = UIBezierPath(roundedRect: rect.insetBy(dx: self.width/2, dy: self.width/2), byRoundingCorners: style.roundedCorners, cornerRadii: CGSizeMake(style.cornerRadius, style.cornerRadius))
                }
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
                
                if let p = context.path {
                    bez = p
                } else {
                    bez = UIBezierPath(roundedRect: rect, byRoundingCorners: style.roundedCorners, cornerRadii: CGSizeMake(style.cornerRadius, style.cornerRadius))
                }
                
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
        if let v = context.view, p = context.path {
            v.layer.shadowPath = p.CGPath
            v.layer.shadowColor = self.color.color.CGColor
            v.layer.shadowOffset = self.offset
            v.layer.shadowRadius = self.radius
        }
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
        var color:UIColor? = _color
        
        if color == nil, let name = self.name {
            if let found = DynUI.colorForName(name) {
                color = found.color
            }
        }
        
        if var color = color {
            color = color.colorWithAlphaComponent(self.alpha)
            if self.brightnessAdjustment != 0 {
                if self.brightnessAdjustment > 0 {
                    color = color.lighterBy(self.brightnessAdjustment)
                } else if self.brightnessAdjustment < 0 {
                    color = color.darkerBy(-self.brightnessAdjustment)
                }
            }
            return color
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
    
    public init(name:StyleNaming, alpha:CGFloat = 1) {
        self.name = name
        self.alpha = alpha
    }
    
    public init(_ name:StyleNaming, alpha:CGFloat = 1) {
        self.name = name
        self.alpha = alpha
    }
    
    public init(withHexAsName:String) {
        _color = UIColor(rgba: withHexAsName)
        self.name = withHexAsName
    }
    
    private var brightnessAdjustment:Double = 0
}

extension Color {
    public func lighterBy(percent : Double) -> Color {
        var new = self
        new.brightnessAdjustment = percent;
        return new
    }

    public func darkerBy(percent : Double) -> Color {
        var new = self
        new.brightnessAdjustment = -percent
        return new
    }
}

extension UIColor {
    private func lighterBy(percent : Double) -> UIColor {
        return colorWithBrightnessFactor(CGFloat(1 + percent));
    }
    
    private func darkerBy(percent : Double) -> UIColor {
        return colorWithBrightnessFactor(CGFloat(1 - percent));
    }
    
    private func colorWithBrightnessFactor(factor: CGFloat) -> UIColor {
        var hue : CGFloat = 0
        var saturation : CGFloat = 0
        var brightness : CGFloat = 0
        var alpha : CGFloat = 0
        
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return UIColor(hue: hue, saturation: saturation, brightness: brightness * factor, alpha: alpha)
        } else {
            return self;
        }
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