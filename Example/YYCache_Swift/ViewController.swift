//
//  ViewController.swift
//  YYCache_Swift
//
//  Created by shenyutao on 09/22/2022.
//  Copyright (c) 2022 shenyutao. All rights reserved.
//

import UIKit
import YYCache_Swift

struct testStoreStruct: Codable {
    var date: Date?
}

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cache = YYCacheSwift.cache(name: "ddd")
        for i in 0..<100000 {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                let cachedDate = cache?.get(type: testStoreStruct.self, key: "test")
                print("sytsyt cache date: \(String(describing: cachedDate?.date))")
                let newCachedDate = testStoreStruct(date: Date())
                cache?.set(key: "test", value: newCachedDate)
                print("sytsyt set cache date")
                print("\(i) done")
            }
        }
//        for i in 0..<10000 {
//            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
//                var newCachedDate = testStoreStruct(date: Date())
//                self.cache?.set(key: "test", value: newCachedDate)
//                print("sytsyt set cache date")
//            }
//        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

