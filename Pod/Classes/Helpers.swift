//
//  UIImageHelpers.swift
//  GifMaker
//
//  Created by Daniel Pourhadi on 3/14/15.
//  Copyright (c) 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import CoreImage

extension UIImage {
    func imageByCropping(toFrame:CGRect) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(toFrame.size, true, self.scale)
        self.drawInRect(CGRectMake(-toFrame.origin.x, -toFrame.origin.y, self.size.width, self.size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    public class func drawImage(size:CGSize, withBlock:(rect:CGRect)->Void) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        withBlock(rect:CGRectMake(0,0,size.width,size.height))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
}

extension CGRect {
    public func centeredIn(rect:CGRect) -> CGRect {
        return CGRect(x: (rect.size.width-self.size.width)/2, y: (rect.size.height-self.size.height)/2, width: self.size.width, height: self.size.height)
    }
}