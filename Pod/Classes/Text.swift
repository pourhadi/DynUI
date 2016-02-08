//
//  Text.swift
//  Pods
//
//  Created by Dan Pourhadi on 1/31/16.
//
//

import Foundation
import RxSwift

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
            if let newValue = newValue, color = newValue.color {
                self.setTitleColor(color.color, forState: .Normal)
            }
        }
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