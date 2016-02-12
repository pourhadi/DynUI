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
        DynUI.prepare()
        var style = ViewStyle(newWithName: "Test")
        style.backgroundStyle = Fill(fillStyle: Color(UIColor.blueColor()))
        
        let serialized = style.ss_serialize()
        print(serialized)
        
//        let string = serialized.toString()
        let backToStyle = serialized.deserialize() as! ViewStyle
        
        DynUI.initialize([], drawableStyles: [backToStyle], textStyles: [])
        
        let testView = UIView(frame: CGRectMake(0,0,200,200))
        self.view.addSubview(testView)
        testView.center = self.view.center
        
        testView.dyn_viewStyle = ViewStyle("Test")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

