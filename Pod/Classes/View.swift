//
//  Extensions.swift
//  DynUISwift
//
//  Created by Daniel Pourhadi on 1/7/16.
//  Copyright © 2016 Daniel Pourhadi. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension NSObject {
    private struct AssociatedKeys {
        static var PropertyManager = "_propertyManager"
    }

    internal var dyn_propertyManager:ExtensionPropertyManager {
        get {
            if let manager = objc_getAssociatedObject(self, &AssociatedKeys.PropertyManager) as? ExtensionPropertyManager {
                return manager
            }
            let manager = ExtensionPropertyManager()
            objc_setAssociatedObject(self, &AssociatedKeys.PropertyManager, manager, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return manager
        }
    }
    
    internal func dyn_getProp<T>(key:String) -> T? {
        return self.dyn_propertyManager.dyn_properties[key] as? T
    }
    
    internal func dyn_setProp<T>(prop:T?,  _ key:String) {
        self.dyn_propertyManager.dyn_properties[key] = prop
    }
}

internal class ExtensionPropertyManager:NSObject {
    var dyn_properties = [String:Any?]()
}

extension UIView {
    public var dyn_styleName:StyleNaming? {
        get {
            if let style = self.dyn_renderableStyles["dyn_styleName"] { return style }
            return nil
        }
        set {
            self.dyn_renderableStyles["dyn_styleName"] = newValue
        }
    }
    
    public var dyn_style:ViewStyle? {
        get {
            if let style = self.dyn_renderableViewStyles["dyn_style"] { return style }
            return nil
        }
        set {
            self.dyn_renderableViewStyles["dyn_style"] = newValue
        }
    }
}

extension UIView {
    public func dyn_forceRerender() {
        self.dyn_lastRecordedFrame = nil
        self.dyn_render()
    }
    
    private var dyn_renderableViewStyles:[String:ViewStyle?] {
        get {
            if let array = (self.dyn_getProp("dyn_renderableViewStyles") as [String:ViewStyle?]?) { return array }
            return [:]
        }
        set {
            self.dyn_setProp(newValue, "dyn_renderableViewStyles")
            self.dyn_setup()
        }
    }
    
    private var dyn_renderableStyles:[String:StyleNaming?] {
        get {
            if let array = (self.dyn_getProp("dyn_renderableStyles") as [String:StyleNaming?]?) { return array }
            return [:]
        }
        set {
            self.dyn_setProp(newValue, "dyn_renderableStyles")
            self.dyn_setup()
        }
    }
    
    private var dyn_disposeBag:DisposeBag? {
        get {
            return self.dyn_getProp("disposeBag")
        }
        set {
            self.dyn_setProp(newValue, "disposeBag")
        }
    }
    
    private var dyn_lastRecordedFrame:CGRect? {
        get { return self.dyn_getProp("dyn_lastRecordedFrame") }
        set { self.dyn_setProp(newValue, "dyn_lastRecordedFrame") }
    }
    
    private func dyn_setup() {
        guard self.dyn_disposeBag == nil else {
            self.dyn_render()
            return
        }
        
        self.dyn_disposeBag = DisposeBag()
        
        self.dyn_disposeBag?.addDisposable(self.rx_observe(CGRect.self, "layer.bounds").subscribeNext({ [weak self] (rect) -> Void in
            log("inside frame observer - \(rect)")
                self?.dyn_render()
        }))
    }
    
    private func dyn_teardown() {
        guard let _ = self.dyn_disposeBag else { return }
        
        self.dyn_disposeBag = nil
    }
    
    private var dyn_numberOfTimesRendered:Int {
        get { if let num = self.dyn_getProp("timesRendered") as Int? { return num } else {
            return 0
            } }
        set { self.dyn_setProp(newValue, "timesRendered") }
    }
    
    private func dyn_render() {
            func render() -> UIImage {
                self.dyn_numberOfTimesRendered += 1
                log("TIMES RENDERED: \(self.dyn_numberOfTimesRendered)")
                return UIImage.drawImage(self.bounds.size, withBlock: { (rect) -> Void in
                    let context = RenderContext.init(rect: self.bounds, view: self,  parameters: nil)
                    for (_, styleName) in self.dyn_renderableStyles {
                        guard let styleName = styleName else { continue }
                        guard let style = DynUI.drawableStyleForName(styleName) else { continue }
                        style.render(context)
                    }
                    
                    for (_, style) in self.dyn_renderableViewStyles {
                        guard let style = style else { continue }
                        style.render(context)
                    }
                })
            }
            
            log("\(self.dyn_styleName)")
        if let lastRecordedFrame = self.dyn_lastRecordedFrame {
            if lastRecordedFrame != self.layer.bounds {
                self.layer.contents = render().CGImage
                self.dyn_lastRecordedFrame = self.layer.bounds
            }
        } else {
            self.dyn_lastRecordedFrame = self.layer.bounds
            if self.layer.bounds.size.width > 0 && self.layer.bounds.size.height > 0 {
                self.layer.contents = render().CGImage
            }
        }
    }
    
    internal var dyn_overlayView:OverlayView {
        get {
            if let v = (self.dyn_getProp("dyn_overlayView") as OverlayView?) {
                return v
            }
            
            let v = OverlayView(attachedTo: self)
            self.dyn_overlayView = v
            return v
        }
        set { self.dyn_setProp(newValue, "dyn_overlayView") }
    }
}

internal class OverlayView: UIImageView {
    unowned var attachedTo:UIView
    init(attachedTo:UIView) {
        self.attachedTo = attachedTo
        super.init(frame: CGRectZero)
        self.setup()
    }
    
    internal override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return false
    }
    
    var disposeBag = DisposeBag()
    func setup() {
        self.backgroundColor = UIColor.clearColor()
        self.attachedTo.rx_observe(UIView.self, "superview").subscribeNext ({ [weak self] (view) -> Void in
            if let this = self {
                if let view = view {
                    view.insertSubview(this, aboveSubview: this.attachedTo)
                } else {
                    this.removeFromSuperview()
                }
            }
        }).addDisposableTo(self.disposeBag)
        
        self.attachedTo.rx_observe(CGPoint.self, "layer.position").subscribeNext ({ [weak self] (point) -> Void in
            if let point = point {
                self?.layer.position = point
            }
        }).addDisposableTo(self.disposeBag)
        
        self.attachedTo.rx_observe(CGRect.self, "layer.bounds").subscribeNext ({ [weak self] (rect) -> Void in
            if let rect = rect {
                self?.layer.bounds = rect
            }
            }).addDisposableTo(self.disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public protocol TextStyleable: class {
    var dyn_textStyle:TextStyle? { get set }
}

extension UILabel: TextStyleable {
    public var dyn_textStyle:TextStyle? {
        get {
            return self.dyn_getProp("dyn_textStyleName")
        }
        set {
            self.dyn_setProp(newValue, "dyn_textStyleName")
            
            if let style = newValue {
                if let _ = self.dyn_textStyleDisposeBag {
                    self.dyn_applyTextStyle(style)
                } else {
                    self.dyn_textStyleDisposeBag = DisposeBag()
                    self.dyn_textStyleDisposeBag!.addDisposable(self.rx_observe(String.self, "text").subscribeNext({ [weak self] (text) -> Void in
                        self?.dyn_applyTextStyle(style)
                        }))
                }
            } else {
                self.dyn_textStyleDisposeBag = nil
                self.dyn_highlightTextStyleDisposeBag = nil
            }
        }
    }
    
    private func dyn_applyTextStyle(style:TextStyle) {
        let attr = style.asAttributes()
        if let text = self.text {
            self.attributedText = NSAttributedString(string: text, attributes: attr)
        } else if let text = self.attributedText {
            self.attributedText = NSAttributedString(string: text.string, attributes: attr)
        }
        
        self.dyn_configureHighlightStyle()
    }
    
    private func dyn_configureHighlightStyle() {
        if let highlightColor = self.dyn_textStyle?.highlightedTextColor {
            if self.dyn_highlightTextStyleDisposeBag != nil { return }
            self.dyn_highlightTextStyleDisposeBag = DisposeBag()
            
            self.dyn_highlightTextStyleDisposeBag!.addDisposable(self.rx_observe(Bool.self, "highlighted").subscribeNext({ [weak self] (_) -> Void in
                if self == nil { return }
                if self?.dyn_textStyle == nil { return }
                if self?.highlighted ?? false {
                    self?.dyn_applyTextStyle(self!.dyn_textStyle!.withColor(highlightColor))
                } else {
                    self?.dyn_applyTextStyle(self!.dyn_textStyle!)
                }
            }))
            
        } else {
            self.dyn_highlightTextStyleDisposeBag = nil
        }
    }
    
    private var dyn_textStyleDisposeBag:DisposeBag? {
        get { return self.dyn_getProp("dyn_textStyleDisposeBag") }
        set { self.dyn_setProp(newValue, "dyn_textStyleDisposeBag") }
    }
    
    private var dyn_highlightTextStyleDisposeBag:DisposeBag? {
        get { return self.dyn_getProp("dyn_highlightTextStyleDisposeBag") }
        set { self.dyn_setProp(newValue, "dyn_highlightTextStyleDisposeBag") }
    }
}

extension UIButton: TextStyleable {
    public var dyn_textStyle:TextStyle? {
        get {
            return self.titleLabel!.dyn_textStyle
        }
        set {
            self.titleLabel!.dyn_textStyle = newValue
        }
    }
    
    public var dyn_buttonStyle:StyleNaming? {
        get {
            if let style = self.dyn_renderableStyles["dyn_buttonStyle"] { return style }
            return nil
        }
        set {
            self.dyn_renderableStyles["dyn_buttonStyle"] = newValue
            
            if let _ = newValue {
                self.dyn_setupButtonStyle()
                self.dyn_applyStyleForState()
            } else { self.dyn_buttonDisposeBag = nil }
        }
    }
    
    private func dyn_applyStyleForState() {
        if let styleName = self.dyn_buttonStyle {
            if let style = DynUI.drawableStyleForName(styleName) as? ButtonStyle {
                self.dyn_lastRecordedFrame = nil
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    if self.highlighted {
                        if let highlightedStyle = style.highlightedViewStyle {
                            self.dyn_styleName = highlightedStyle
                        }
                        if let highlightedTextStyle = style.highlightedTextStyle {
                            self.dyn_textStyle = highlightedTextStyle
                        }
                    } else {
                        self.dyn_styleName = style.viewStyle
                        self.dyn_textStyle = style.textStyle
                    }
                })
            }
        }
    }
    
    private var dyn_buttonDisposeBag:DisposeBag? {
        get { return self.dyn_getProp("dyn_buttonDisposeBag") }
        set { self.dyn_setProp(newValue, "dyn_buttonDisposeBag") }
    }
    
    private func dyn_setupButtonStyle() {
        guard self.dyn_buttonDisposeBag == nil else { return }
        
        self.dyn_buttonDisposeBag = DisposeBag()
        
        self.dyn_buttonDisposeBag!.addDisposable(self.rx_observe(Bool.self, "highlighted").subscribeNext ({ [weak self] (highlighted) -> Void in
            if let this = self {
                if !this.highlighted {
                    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
                    dispatch_after(time, dispatch_get_main_queue()) {
                        this.dyn_applyStyleForState()
                    }
                } else {
                    this.dyn_applyStyleForState()
                }
            }
        }))
    }
}

extension UITextField: TextStyleable {
    public var dyn_textStyle:TextStyle? {
        get {
            return self.dyn_getProp("dyn_textStyle")
        }
        set {
            self.dyn_setProp(newValue, "dyn_textStyle")
            if let style = newValue {
                self.defaultTextAttributes = style.asAttributes()
            }
        }
    }
}
