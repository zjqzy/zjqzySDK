//
//  ViewController.swift
//  zjqzySDK
//
//  Created by zhu jianqi on 2019/5/20.
//  Copyright © 2019 zhu jianqi. All rights reserved.
//

import UIKit


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    // MARK: - 旋转 -
    override var shouldAutorotate: Bool{
        return true
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        }
        
        return .all
    }
    
    // MARK: - 其他 -
    func openFile()->Void{
        
        print("open");
    }
}

