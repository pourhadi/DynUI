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
        public var dyn_viewStyle:ViewStyle? {
        get {
            return self.dyn_getRenderableStyle("dyn_viewStyle")
        }
        set {
            self.dyn_setRenderableStyle("dyn_viewStyle", style: newValue)
        }
    }
}

extension UIView {
    public func dyn_forceRerender() {
        self.dyn_lastRecordedFrame = nil
        self.dyn_render()
    }
    
    internal func dyn_getRenderableStyle<T:Renderable>(key:String) -> T? {
        return self.dyn_renderableViewStyles[key] as? T
    }
    
    internal func dyn_setRenderableStyle<T:Renderable>(key:String, style:T?) {
        self.dyn_renderableViewStyles[key] = style
    }
    
    internal var dyn_renderableViewStyles:[String:Renderable?] {
        get {
            if let array = (self.dyn_getProp("dyn_renderableViewStyles") as [String:Renderable?]?) { return array }
            return [:]
        }
        set {
            self.dyn_setProp(newValue, "dyn_renderableViewStyles")
            self.dyn_setup()
        }
    }
 
    internal var dyn_disposeBag:DisposeBag? {
        get {
            return self.dyn_getProp("disposeBag")
        }
        set {
            self.dyn_setProp(newValue, "disposeBag")
        }
    }
    
    internal var dyn_lastRecordedFrame:CGRect? {
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
            guard self?.layer.bounds.size.width > 0 else { return }
            guard self?.layer.bounds.size.height > 0 else { return }
            log("inside frame observer - \(rect)")
            self?.dyn_render()
        }))
    }
    
    private func dyn_teardown() {
        guard let _ = self.dyn_disposeBag else { return }
        
        self.dyn_disposeBag = nil
    }
    
    internal var dyn_numberOfTimesRendered:Int {
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
                    for (_, style) in self.dyn_renderableViewStyles {
                        guard let style = style else { continue }
                        style.render(context)
                    }
                })
            }
            
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
        
        self.attachedTo.rx_observe(CGAffineTransform.self, "transform").subscribeNext ({ [weak self] (transform) -> Void in
            if let transform = transform {
                self?.transform = transform
            }
            }).addDisposableTo(self.disposeBag)
        
        self.attachedTo.rx_observe(CGFloat.self, "alpha").subscribeNext ({ [weak self] (alpha) -> Void in
            if let alpha = alpha {
                self?.alpha = alpha
            }
            }).addDisposableTo(self.disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIButton {
    
    public var dyn_buttonStyle:ButtonStyle? {
        get {
            return self.dyn_getRenderableStyle("dyn_buttonStyle")
        }
        set {
            self.dyn_setRenderableStyle("dyn_buttonStyle", style: newValue)
            
            if let _ = newValue {
                self.dyn_setupButtonStyle()
                self.dyn_applyStyleForState()
            } else { self.dyn_buttonDisposeBag = nil }
        }
    }
    
    private func dyn_applyStyleForState() {
        if let style = self.dyn_buttonStyle {
            self.dyn_lastRecordedFrame = nil
            self.dyn_textStyle = style.textStyle
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                if self.highlighted {
                    if let highlightedStyle = style.highlightedViewStyle {
                        self.dyn_viewStyle = highlightedStyle
                    }
                } else {
                    self.dyn_viewStyle = style.viewStyle
                }
            })
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



