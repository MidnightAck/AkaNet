//
//  ViewController.swift
//  AkaNetExample
//
//  Created by Siyuan on 2024/7/1.
//

import UIKit
import AkaNet

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        testGet()
    }
    
    


}


extension ViewController {
    func testGet() {
        AkaNetworkService.GET(address: "www.baidu.com", params: [:]) { data in
            print("🐱🐱🐱🐱🐱1")
        }
    }
}
