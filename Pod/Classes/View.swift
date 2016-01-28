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

    private var dyn_propertyManager:ExtensionPropertyManager {
        get {
            if let manager = objc_getAssociatedObject(self, &AssociatedKeys.PropertyManager) as? ExtensionPropertyManager {
                return manager
            }
            let manager = ExtensionPropertyManager()
            objc_setAssociatedObject(self, &AssociatedKeys.PropertyManager, manager, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return manager
        }
    }
    
    private func dyn_getProp<T>(key:String) -> T? {
        return self.dyn_propertyManager.dyn_properties[key] as? T
    }
    
    private func dyn_setProp<T>(prop:T?,  _ key:String) {
        self.dyn_propertyManager.dyn_properties[key] = prop
    }
}

private class ExtensionPropertyManager:NSObject {
    var dyn_properties = [String:Any?]()
}

extension UIView {
    public var dyn_styleName:StyleNaming? {
        get {
            return self.dyn_getProp("dyn_styleName")
        }
        set {
            self.dyn_setProp(newValue, "dyn_styleName")
            self.dyn_setup()
        }
    }
}

extension UIView {
    private var dyn_disposeBag:DisposeBag? {
        get {
            return self.dyn_getProp("disposeBag")
        }
        set {
            self.dyn_setProp(newValue, "disposeBag")
        }
    }
    
    private func dyn_setup() {
        guard self.dyn_disposeBag == nil else { return }
        self.dyn_disposeBag = DisposeBag()
        
        log(self.dyn_disposeBag == nil ? "dispose bag nil" : "dispose bag not nil")

        var lastRecordedFrame:CGRect? = CGRectZero
        self.dyn_disposeBag?.addDisposable(self.rx_observe(CGRect.self, "layer.bounds").subscribeNext({ [weak self] (rect) -> Void in
            log("inside frame observer - \(rect)")

            if rect != lastRecordedFrame {
                lastRecordedFrame = rect
                self?.dyn_render()
            }
        }))
    }
    
    private func dyn_teardown() {
        guard let _ = self.dyn_disposeBag else { return }
        
        self.dyn_disposeBag = nil
    }
    
    private func dyn_render() {
        func render(style:ViewStyle) -> UIImage {
            return UIImage.drawImage(self.bounds.size, withBlock: { (rect) -> Void in
                let context = RenderContext.init(rect: self.bounds, view: self,  parameters: nil)
                style.render(context)
            })
        }
        
        log("\(self.dyn_styleName)")
        log("\(DynUI.drawableStyles)")
        guard let styleName = self.dyn_styleName else { return }
        guard let style = DynUI.drawableStyleForName(styleName) as? ViewStyle else { return }
        
        if style.renderAsynchronously {
            dispatch_async(DynUI.renderQueue, { [weak self] () -> Void in
                let image = render(style)
                dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                    self?.layer.contents = image.CGImage
                })
            })
        } else {
            self.layer.contents = render(style).CGImage
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
    var dyn_textStyle:(name:StyleNaming, size:CGFloat)? { get set }
}

extension UILabel: TextStyleable {
    public var dyn_textStyle:(name:StyleNaming, size:CGFloat)? {
        get {
            return self.dyn_getProp("dyn_textStyleName")
        }
        set {
            self.dyn_setProp(newValue, "dyn_textStyleName")
            
            if let t = newValue {
                if let style = DynUI.textStyleForName(t) {
                    self.font = style.font
                    if let alignment = style.alignment { self.textAlignment = alignment }
                    if let color = style.color { self.textColor = color.color }
                    if let shadow = style.shadow {
                        self.shadowColor = shadow.color.color
                        self.shadowOffset = shadow.offset
                    }
                }
            }
        }
    }
}

extension UIButton: TextStyleable {
    public var dyn_textStyle:(name:StyleNaming, size:CGFloat)? {
        get {
            return self.titleLabel!.dyn_textStyle
        }
        set {
            self.titleLabel!.dyn_textStyle = newValue
        }
    }
}

extension UITextField: TextStyleable {
    public var dyn_textStyle:(name:StyleNaming, size:CGFloat)? {
        get {
            return self.dyn_getProp("dyn_textStyle")
        }
        set {
            self.dyn_setProp(newValue, "dyn_textStyle")
            guard let styleName = newValue else { return }
            if let style = DynUI.textStyleForName(styleName) {
                self.defaultTextAttributes = style.asAttributes()
            }
        }
    }
}
