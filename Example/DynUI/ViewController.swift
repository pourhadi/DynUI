//
//  ViewController.swift
//  DynUI
//
//  Created by Daniel Pourhadi on 01/19/2016.
//  Copyright (c) 2016 Daniel Pourhadi. All rights reserved.
//

import UIKit
import DynUI

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        var attr = [DrawingStyleAttribute]()
        
        let fill = Fill(fillStyle:Color(color:UIColor.redColor()))
        let border = Border(width: 8, color: Color(color: UIColor.blueColor()), roundedCorners: .AllCorners, cornerRadius: 4)
        
        attr.append(fill)
        attr.append(border)
        
        let style = DrawingStyle(name: "Test", attributes: attr)
        
        DynUI.drawingStyles.append(style)

        
        let testView = UIView(frame: CGRectMake(0,0,400,400))
        self.view.addSubview(testView)
        
        testView.dyn_styleName = "Test"
        
        testView.center = self.view.center
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

