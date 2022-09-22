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
    let cache = YYCacheSwift.cache(name: "ddd")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var cachedDate = cache?.get(type: testStoreStruct.self, key: "test")
        print("cache date: \(String(describing: cachedDate?.date))")
        var newCachedDate = cachedDate ?? .init()
        newCachedDate.date = Date()
        cache?.set(key: "test", value: newCachedDate)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

