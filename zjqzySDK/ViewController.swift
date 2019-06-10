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
        
        CNKIServerOData.sharedInstance.z_initPare("1")("2")("3")
        
        CNKIServerCAJCloud.sharedInstance.block_custom = {(para1) -> () in
            //cusValue就是传过来的值
            print("^_^:\(para1!)")
        }
        
        _ = CNKIServerCAJCloud.sharedInstance.z_Server("123")?.z_appKey("234")?.z_appSecretKey("345")
       
//        let jsonFilePath = Bundle.main.path(forResource: "cnki_server", ofType: "json");
//        _=CNKIServerCAJCloud.sharedInstance.load(jsonFilePath: jsonFilePath!)
        

        ZJQLogger.zPrint("\(CNKIServerCAJCloud.sharedInstance.cnki_cajcloud_Server)+\(CNKIServerCAJCloud.sharedInstance.appKey)+\(CNKIServerCAJCloud.sharedInstance.appSecretKey)")
        
        
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

