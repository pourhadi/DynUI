//
//  Popover.swift
//  Pods
//
//  Created by Dan Pourhadi on 1/29/16.
//
//

import Foundation
import UIKit

let CAP_INSET:CGFloat = 25
let ARROW_BASE:CGFloat = 38
let ARROW_HEIGHT:CGFloat = 20

extension UIPopoverController {
    public static var dyn_popoverStyle:ViewStyle?
    public static var dyn_contentInset:UIEdgeInsets?
}

public class PopoverStyleClass: UIPopoverBackgroundView {
    
    let borderImageView:UIImageView = UIImageView(frame: CGRectZero)
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.borderImageView.frame = self.bounds
        self.backgroundColor = UIColor.clearColor()
        self.addSubview(self.borderImageView)
    }
    
    override public class func wantsDefaultContentAppearance() -> Bool {
        return false
    }
    
    public override static func contentViewInsets() -> UIEdgeInsets {
        return UIPopoverController.dyn_contentInset ?? UIEdgeInsetsMake(10, 10, 10, 10)
    }
    
    private var _arrowDirection:UIPopoverArrowDirection = .Any
    override public var arrowDirection: UIPopoverArrowDirection {
        get {
            return _arrowDirection
        }
        set {
            _arrowDirection = newValue
        }
    }

    private var _arrowOffset:CGFloat = 0
    override public var arrowOffset: CGFloat {
        get {
            return _arrowOffset
        }
        set {
            _arrowOffset = newValue
        }
    }
    
    public override static func arrowHeight() -> CGFloat {
        return ARROW_HEIGHT
    }
    
    public override static func arrowBase() -> CGFloat {
        return ARROW_BASE
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        var _height = self.frame.size.height
        var _width = self.frame.size.width
        var _left:CGFloat = 0
        var _top:CGFloat = 0
        var _coordinate:CGFloat = 0
        
        let offset:CGFloat = 0
        var arrowRect:CGRect = CGRectZero
        
        switch self.arrowDirection {
        case UIPopoverArrowDirection.Up:
            _top += ARROW_HEIGHT
            _height -= ARROW_HEIGHT
            _coordinate = ((self.frame.size.width / 2) + self.arrowOffset) - (ARROW_BASE / 2)
            arrowRect = CGRectMake(_coordinate, 0 + offset, ARROW_BASE, ARROW_HEIGHT)
        case UIPopoverArrowDirection.Down:
            _height -= ARROW_HEIGHT
            _coordinate = ((self.frame.size.width / 2) + self.arrowOffset) - (ARROW_BASE / 2)
            arrowRect = CGRectMake(_coordinate, _height - offset, ARROW_BASE, ARROW_HEIGHT)
        case UIPopoverArrowDirection.Left:
            _left += ARROW_HEIGHT
            _width -= ARROW_HEIGHT
            _coordinate = ((self.frame.size.height / 2) + self.arrowOffset) - (ARROW_BASE / 2)
            arrowRect = CGRectMake(offset, _coordinate, ARROW_HEIGHT, ARROW_BASE)
        case UIPopoverArrowDirection.Right:
            _width -= ARROW_HEIGHT
            _coordinate = ((self.frame.size.height / 2) + self.arrowOffset) - (ARROW_BASE / 2)
            arrowRect = CGRectMake(_width - offset, _coordinate, ARROW_HEIGHT, ARROW_BASE)
        default: break
        }
        
        self.borderImageView.frame = self.bounds
        self.borderImageView.image = self.getBgImage(self.bounds.size, arrowRect: arrowRect, bgRect: CGRectMake(_left + 1, _top + 1, _width - 2, _height - 2))?.stretchableImageWithLeftCapWidth(Int(self.bounds.size.width) / 2 - (1), topCapHeight: Int(self.bounds.size.height) / 2 - 1)
    }
    
    func getBgImage(size:CGSize, arrowRect:CGRect, bgRect:CGRect) -> UIImage? {
        guard let style = UIPopoverController.dyn_popoverStyle else { return nil }
        let path = UIBezierPath()
        let radius = CGSizeMake(style.cornerRadius, style.cornerRadius)
        
        path.moveToPoint(CGPointMake(bgRect.origin.x, bgRect.origin.y + radius.height))
        if style.roundedCorners.contains(.TopLeft) {
            path.addArcWithCenter(CGPointMake(path.currentPoint.x + radius.width, path.currentPoint.y), radius: radius.width, startAngle: CGFloat(M_PI), endAngle: CGFloat(3 * M_PI) / 2, clockwise: true)
        } else {
            path.addLineToPoint(bgRect.origin)
        }
        
        if (self.arrowDirection == .Up) {
            path.addLineToPoint(CGPointMake(arrowRect.origin.x, bgRect.origin.y))
            path.addLineToPoint(CGPointMake(arrowRect.origin.x + (arrowRect.size.width / 2), 1))
            path.addLineToPoint(CGPointMake(arrowRect.origin.x + arrowRect.size.width, bgRect.origin.y))
        }
        
        path.addLineToPoint(CGPointMake((bgRect.origin.x + bgRect.size.width) - radius.width, bgRect.origin.y))
        
        if (style.roundedCorners.contains(.TopRight)) {
            path.addArcWithCenter(CGPointMake(path.currentPoint.x, path.currentPoint.y + radius.height), radius:radius.width, startAngle:CGFloat(3 * M_PI) / 2, endAngle:0, clockwise:true)
        } else {
            path.addLineToPoint(CGPointMake(bgRect.origin.x + bgRect.size.width, bgRect.origin.y))
        }
        
        if (self.arrowDirection == .Right) {
            path.addLineToPoint(CGPointMake(bgRect.origin.x + bgRect.size.width, arrowRect.origin.y))
            path.addLineToPoint(CGPointMake(arrowRect.origin.x + arrowRect.size.width, arrowRect.origin.y + (arrowRect.size.height / 2)))
            path.addLineToPoint(CGPointMake(bgRect.origin.x + bgRect.size.width, arrowRect.origin.y + arrowRect.size.height))
        }
        
        path.addLineToPoint(CGPointMake(bgRect.origin.x + bgRect.size.width, (bgRect.origin.y + bgRect.size.height) - radius.height))
        
        if (style.roundedCorners.contains(.BottomRight)) {
            path.addArcWithCenter(CGPointMake(path.currentPoint.x - radius.width, path.currentPoint.y), radius:radius.width, startAngle:0, endAngle:CGFloat(M_PI / 2), clockwise:true)
        } else {
            path.addLineToPoint(CGPointMake(CGRectGetMaxX(bgRect), CGRectGetMaxY(bgRect)))
        }
        
        if (self.arrowDirection == .Down) {
            path.addLineToPoint(CGPointMake(arrowRect.origin.x + arrowRect.size.width, bgRect.origin.y + bgRect.size.height))
            path.addLineToPoint(CGPointMake(arrowRect.origin.x + (arrowRect.size.width / 2), arrowRect.origin.y + arrowRect.size.height))
            path.addLineToPoint(CGPointMake(arrowRect.origin.x, bgRect.origin.y + bgRect.size.height))
        }
        
        path.addLineToPoint(CGPointMake(bgRect.origin.x + radius.width, bgRect.origin.y + bgRect.size.height))
        
        // bottom left
        if (style.roundedCorners.contains(.BottomLeft)) {
            path.addArcWithCenter(CGPointMake(path.currentPoint.x, path.currentPoint.y - radius.height), radius:radius.width, startAngle:CGFloat(M_PI / 2), endAngle:CGFloat(M_PI), clockwise:true)
        } else {
            path.addLineToPoint(CGPointMake(bgRect.origin.x, CGRectGetMaxY(bgRect)))
        }
        
        if (self.arrowDirection == .Left) {
            path.addLineToPoint(CGPointMake(bgRect.origin.x, arrowRect.origin.y + arrowRect.size.height))
            path.addLineToPoint(CGPointMake(arrowRect.origin.x, arrowRect.origin.y + (arrowRect.size.height / 2)))
            path.addLineToPoint(CGPointMake(bgRect.origin.x, arrowRect.origin.y))
        }
        
        path.closePath()
        
        let image = UIImage.drawImage(size) { (rect) -> Void in
            style.render(RenderContext(path: path, view: self))
        }
        
        return image
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}