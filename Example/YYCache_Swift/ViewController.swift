//
//  ViewController.swift
//  YYCache_Swift
//
//  Created by shenyutao on 09/22/2022.
//  Copyright (c) 2022 shenyutao. All rights reserved.
//

import UIKit
import YYCache_Swift

struct StoreCodable: Codable {
    var date: Date? = Date()
    var string: String?
}

class StoreCoding: NSObject, NSCoding {
    func encode(with coder: NSCoder) {
        coder.encode(date, forKey: "date")
        coder.encode(string, forKey: "string")
    }
    
    required init?(coder: NSCoder) {
        date = coder.decodeObject(of: NSDate.self, forKey: "date") as? Date
        string = coder.decodeObject(of: NSString.self, forKey: "string") as? String
    }
    
    var date: Date? = Date()
    var string: String?
    
    init(string: String?) {
        super.init()
        self.string = string
    }
}

struct Options: OptionSet {
    var rawValue: UInt
    static let memory = Options(rawValue: 1)
    static let disk = Options(rawValue: 2)
}

class ViewController: UIViewController {
    var cache: YYCacheSwift? = {
        let cache = YYCacheSwift.cache(name: "ddd")
        cache?.memoryCache.ageLimit = 20
        cache?.diskCache.ageLimit = 20
        cache?.memoryCache.autoTrimInterval = 10
        cache?.diskCache.autoTrimInterval = 10
        return cache
    }()
    
    var options: Options = [.memory, .disk] {
        didSet {
            let memory = options.contains(.memory) ? "使用内存存储" : "禁用内存存储"
            let disk = options.contains(.disk) ? "使用磁盘存储" : "禁用磁盘存储"
            memoryBtn.setTitle(memory, for: .normal)
            diskBtn.setTitle(disk, for: .normal)
        }
    }
    
    private lazy var text: UITextField = {
        let text = UITextField(frame: .init(x: 16, y: 80, width: UIScreen.main.bounds.width - 32, height: 32))
        text.placeholder = "Key"
        return text
    }()
    private var memoryBtn: UIButton!
    private var diskBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(text)
        
        setupOptionbuttons()
        setupViews()
        setupNewASyncViews()
    }
}

private extension ViewController {
    func show(_ obj: StoreCodable?) {
        var alertTitle = "read failed"
        var alertMsg = ""
        if let obj = obj {
            alertTitle = "read successed"
            alertMsg = "\(obj.string ?? ""), \(String(describing: obj.date))"
        }
        show(alertTitle: alertTitle, alertMsg: alertMsg)
    }
    
    func show(_ obj: StoreCoding?) {
        var alertTitle = "read failed"
        var alertMsg = ""
        if let obj = obj {
            alertTitle = "read successed"
            alertMsg = "\(obj.string ?? ""), \(String(describing: obj.date))"
        }
        show(alertTitle: alertTitle, alertMsg: alertMsg)
    }
    
    func show(alertTitle: String, alertMsg: String? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: alertTitle, message: alertMsg, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

private extension ViewController {
    
    func setupOptionbuttons() {
        let buttonMemory = UIButton(frame: .init(x: 16, y: 80 + 48.0 * 13, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "使用内存存储", handler: { action in
            if self.options.contains(.memory) {
                self.options.remove(.memory)
            } else {
                self.options.insert(.memory)
            }
        }))
        buttonMemory.backgroundColor = .darkGray
        let buttonDisk = UIButton(frame: .init(x: 16 +  UIScreen.main.bounds.width / 2, y: 80 + 48.0 * 13, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "使用磁盘存储", handler: { action in
            if self.options.contains(.disk) {
                self.options.remove(.disk)
            } else {
                self.options.insert(.disk)
            }
        }))
        buttonDisk.backgroundColor = .darkGray
        self.memoryBtn = buttonMemory
        self.diskBtn = buttonDisk
        view.addSubview(buttonMemory)
        view.addSubview(buttonDisk)
    }
    
    func setupViews() {
        let buttonToStoreCodable = UIButton(frame: .init(x: 16, y: 80 + 48.0, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "同步存储codable", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                self.cache?.set(key: self.text.text ?? "", value: StoreCodable(string: self.text.text))
                self.show(alertTitle: "存储成功")
            } else if self.options.contains(.disk) {
                self.cache?.diskCache.set(key: self.text.text ?? "", value: StoreCodable(string: self.text.text))
                self.show(alertTitle: "存储成功")
            } else if self.options.contains(.memory) {
                self.cache?.memoryCache[self.text.text ?? ""] = StoreCodable(string: self.text.text)
                self.show(alertTitle: "存储成功")
            }
        }))
        buttonToStoreCodable.backgroundColor = .gray
        view.addSubview(buttonToStoreCodable)
        
        let buttonToStoreCoding = UIButton(frame: .init(x: UIScreen.main.bounds.width / 2 + 16, y: 80 + 48.0, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "同步存储NSCoding", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                self.cache?.set(key: self.text.text ?? "", value: StoreCoding(string: self.text.text))
                self.show(alertTitle: "存储成功")
            } else if self.options.contains(.disk) {
                self.cache?.diskCache.set(key: self.text.text ?? "", value: StoreCoding(string: self.text.text))
                self.show(alertTitle: "存储成功")
            } else if self.options.contains(.memory) {
                self.cache?.memoryCache[self.text.text ?? ""] = StoreCoding(string: self.text.text)
                self.show(alertTitle: "存储成功")
            }
        }))
        buttonToStoreCoding.backgroundColor = .gray
        view.addSubview(buttonToStoreCoding)
        
        
        let buttonToReadCodable = UIButton(frame: .init(x: 16, y: 80 + 48.0 * 2, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "同步读取codable", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                self.show(self.cache?.get(type: StoreCodable.self, key: self.text.text ?? ""))
            } else if self.options.contains(.disk) {
                self.show(self.cache?.diskCache.get(type: StoreCodable.self, key: self.text.text ?? ""))
            } else if self.options.contains(.memory) {
                self.show(self.cache?.memoryCache.get(key: self.text.text ?? "") as? StoreCodable)
            }
        }))
        buttonToReadCodable.backgroundColor = .gray
        view.addSubview(buttonToReadCodable)
        
        let buttonToReadCoding = UIButton(frame: .init(x: UIScreen.main.bounds.width / 2 + 16, y: 80 + 48.0 * 2, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "同步读取NSCoding", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                self.show(self.cache?.get(type: StoreCoding.self, key: self.text.text ?? ""))
            } else if self.options.contains(.disk) {
                self.show(self.cache?.diskCache.get(type: StoreCoding.self, key: self.text.text ?? ""))
            } else if self.options.contains(.memory) {
                self.show(self.cache?.memoryCache.get(key: self.text.text ?? "") as? StoreCoding)
            }
        }))
        buttonToReadCoding.backgroundColor = .gray
        view.addSubview(buttonToReadCoding)
        
        let buttonToRemove = UIButton(frame: .init(x: 16, y: 80 + 48.0 * 3, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "同步删除Key", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                self.cache?.remove(key: self.text.text ?? "")
                self.show(alertTitle: "删除成功")
            } else if self.options.contains(.disk) {
                self.cache?.diskCache.remove(key: self.text.text ?? "")
                self.show(alertTitle: "删除成功")
            } else if self.options.contains(.memory) {
                self.cache?.memoryCache.remove(forKey: self.text.text ?? "")
                self.show(alertTitle: "删除成功")
            }
        }))
        buttonToRemove.backgroundColor = .gray
        view.addSubview(buttonToRemove)
        
        let buttonToRemoveAll = UIButton(frame: .init(x: UIScreen.main.bounds.width / 2 + 16, y: 80 + 48.0 * 3, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "同步删除全部", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                self.cache?.removeAll()
                self.show(alertTitle: "删除成功")
            } else if self.options.contains(.disk) {
                self.cache?.removeAll()
                self.show(alertTitle: "删除成功")
            } else if self.options.contains(.memory) {
                self.cache?.removeAll()
                self.show(alertTitle: "删除成功")
            }
        }))
        buttonToRemoveAll.backgroundColor = .gray
        view.addSubview(buttonToRemoveAll)
        
        
        
        let buttonToStoreCodableAsync = UIButton(frame: .init(x: 16, y: 80 + 48.0 * 5, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "异步存储codable", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                self.cache?.set(key: self.text.text ?? "", value: StoreCodable(string: self.text.text), completion: {
                    self.show(alertTitle: "存储成功")
                })
            } else if self.options.contains(.disk) {
                self.cache?.diskCache.set(key: self.text.text ?? "", value: StoreCodable(string: self.text.text), completion: {
                    self.show(alertTitle: "存储成功")
                })
            } else if self.options.contains(.memory) {
                self.cache?.memoryCache[self.text.text ?? ""] = StoreCodable(string: self.text.text)
                self.show(alertTitle: "存储成功")
            }
        }))
        buttonToStoreCodableAsync.backgroundColor = .gray
        view.addSubview(buttonToStoreCodableAsync)
        
        let buttonToStoreCodingAsync = UIButton(frame: .init(x: UIScreen.main.bounds.width / 2 + 16, y: 80 + 48.0 * 5, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "异步存储NSCoding", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                self.cache?.set(key: self.text.text ?? "", value: StoreCoding(string: self.text.text), completion: {
                    self.show(alertTitle: "存储成功")
                })
            } else if self.options.contains(.disk) {
                self.cache?.diskCache.set(key: self.text.text ?? "", value: StoreCoding(string: self.text.text), completion: {
                    self.show(alertTitle: "存储成功")
                })
            } else if self.options.contains(.memory) {
                self.cache?.memoryCache[self.text.text ?? ""] = StoreCoding(string: self.text.text)
                self.show(alertTitle: "存储成功")
            }
        }))
        buttonToStoreCodingAsync.backgroundColor = .gray
        view.addSubview(buttonToStoreCodingAsync)
        
        
        let buttonToReadCodableAsync = UIButton(frame: .init(x: 16, y: 80 + 48.0 * 6, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "异步读取codable", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                self.cache?.get(type: StoreCodable.self, key: self.text.text ?? "") {
                    self.show($1)
                }
            } else if self.options.contains(.disk) {
                self.cache?.diskCache.get(type: StoreCodable.self, key: self.text.text ?? "") {
                    self.show($1)
                }
            } else if self.options.contains(.memory) {
                self.show(self.cache?.memoryCache[self.text.text ?? ""] as? StoreCodable)
            }
        }))
        buttonToReadCodableAsync.backgroundColor = .gray
        view.addSubview(buttonToReadCodableAsync)
        
        let buttonToReadCodingAsync = UIButton(frame: .init(x: UIScreen.main.bounds.width / 2 + 16, y: 80 + 48.0 * 6, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "异步读取NSCoding", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                self.cache?.get(type: StoreCoding.self, key: self.text.text ?? "") { self.show($1) }
            } else if self.options.contains(.disk) {
                self.cache?.diskCache.get(type: StoreCoding.self, key: self.text.text ?? "") {
                    self.show($1)
                }
            } else if self.options.contains(.memory) {
                self.show(self.cache?.memoryCache[self.text.text ?? ""] as? StoreCoding)
            }
        }))
        buttonToReadCodingAsync.backgroundColor = .gray
        view.addSubview(buttonToReadCodingAsync)
        
        let buttonToRemoveAsync = UIButton(frame: .init(x: 16, y: 80 + 48.0 * 7, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "异步删除Key", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                self.cache?.remove(key: self.text.text ?? "") { _ in
                    self.show(alertTitle: "删除成功")
                }
            } else if self.options.contains(.disk) {
                self.cache?.diskCache.remove(key: self.text.text ?? "") { _ in
                    self.show(alertTitle: "删除成功")
                }
            } else if self.options.contains(.memory) {
                self.cache?.memoryCache.remove(forKey: self.text.text ?? "")
                self.show(alertTitle: "删除成功")
            }
        }))
        buttonToRemoveAsync.backgroundColor = .gray
        view.addSubview(buttonToRemoveAsync)
        
        let buttonToRemoveAllAsync = UIButton(frame: .init(x: UIScreen.main.bounds.width / 2 + 16, y: 80 + 48.0 * 7, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "异步删除全部", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                self.cache?.removeAll() {
                    self.show(alertTitle: "删除成功")
                }
            } else if self.options.contains(.disk) {
                self.cache?.diskCache.removeAll() {
                    self.show(alertTitle: "删除成功")
                }
            } else if self.options.contains(.memory) {
                self.cache?.memoryCache.removeAll()
                self.show(alertTitle: "删除成功")
            }
        }))
        buttonToRemoveAllAsync.backgroundColor = .gray
        view.addSubview(buttonToRemoveAllAsync)
    }
    
    
    func setupNewASyncViews() {
        
        let buttonToStoreCodableAsync = UIButton(frame: .init(x: 16, y: 80 + 48.0 * 9, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "异步存储codable", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                Task {
                    await self.cache?.setAsync(key: self.text.text ?? "", value: StoreCodable(string: self.text.text))
                    self.show(alertTitle: "存储成功")
                }
            } else if self.options.contains(.disk) {
                Task {
                    await self.cache?.diskCache.setAsync(key: self.text.text ?? "", value: StoreCodable(string: self.text.text))
                    self.show(alertTitle: "存储成功")
                }
            } else if self.options.contains(.memory) {
                Task {
                    self.cache?.memoryCache[self.text.text ?? ""] = StoreCodable(string: self.text.text)
                    self.show(alertTitle: "存储成功")
                }
            }
        }))
        buttonToStoreCodableAsync.backgroundColor = .gray
        view.addSubview(buttonToStoreCodableAsync)
        
        let buttonToStoreCodingAsync = UIButton(frame: .init(x: UIScreen.main.bounds.width / 2 + 16, y: 80 + 48.0 * 9, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "异步存储NSCoding", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                Task {
                    await self.cache?.setAsync(key: self.text.text ?? "", value: StoreCoding(string: self.text.text))
                    self.show(alertTitle: "存储成功")
                }
            } else if self.options.contains(.disk) {
                Task {
                    await self.cache?.diskCache.setAsync(key: self.text.text ?? "", value: StoreCoding(string: self.text.text))
                    self.show(alertTitle: "存储成功")
                }
            } else if self.options.contains(.memory) {
                Task {
                    self.cache?.memoryCache[self.text.text ?? ""] = StoreCoding(string: self.text.text)
                    self.show(alertTitle: "存储成功")
                }
            }
        }))
        buttonToStoreCodingAsync.backgroundColor = .gray
        view.addSubview(buttonToStoreCodingAsync)
        
        
        let buttonToReadCodableAsync = UIButton(frame: .init(x: 16, y: 80 + 48.0 * 10, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "异步读取codable", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                Task {
                    self.show(await self.cache?.getAsync(type: StoreCodable.self, key: self.text.text ?? ""))
                }
            } else if self.options.contains(.disk) {
                Task {
                    self.show(await self.cache?.diskCache.getAsync(type: StoreCodable.self, key: self.text.text ?? ""))
                }
            } else if self.options.contains(.memory) {
                Task {
                    self.show(self.cache?.memoryCache[self.text.text ?? ""] as? StoreCodable)
                }
            }
        }))
        buttonToReadCodableAsync.backgroundColor = .gray
        view.addSubview(buttonToReadCodableAsync)
        
        let buttonToReadCodingAsync = UIButton(frame: .init(x: UIScreen.main.bounds.width / 2 + 16, y: 80 + 48.0 * 10, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "异步读取NSCoding", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                Task {
                    self.show(await self.cache?.getAsync(type: StoreCoding.self, key: self.text.text ?? ""))
                }
            } else if self.options.contains(.disk) {
                Task {
                    self.show(await self.cache?.diskCache.getAsync(type: StoreCoding.self, key: self.text.text ?? ""))
                }
            } else if self.options.contains(.memory) {
                Task {
                    self.show(self.cache?.memoryCache[self.text.text ?? ""] as? StoreCoding)
                }
            }
        }))
        buttonToReadCodingAsync.backgroundColor = .gray
        view.addSubview(buttonToReadCodingAsync)
        
        let buttonToRemoveAsync = UIButton(frame: .init(x: 16, y: 80 + 48.0 * 11, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "异步删除codable", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                Task {
                    await self.cache?.removeAsync(key: self.text.text ?? "")
                    self.show(alertTitle: "删除成功")
                }
            } else if self.options.contains(.disk) {
                Task {
                    await self.cache?.diskCache.removeAsync(key: self.text.text ?? "")
                    self.show(alertTitle: "删除成功")
                }
            } else if self.options.contains(.memory) {
                Task {
                    self.cache?.memoryCache.remove(forKey: self.text.text ?? "")
                    self.show(alertTitle: "删除成功")
                }
            }
        }))
        buttonToRemoveAsync.backgroundColor = .gray
        view.addSubview(buttonToRemoveAsync)
        
        let buttonToRemoveAllAsync = UIButton(frame: .init(x: UIScreen.main.bounds.width / 2 + 16, y: 80 + 48.0 * 11, width: UIScreen.main.bounds.width / 2 - 32, height: 32), primaryAction: .init(title: "异步删除全部", handler: { _ in
            if self.options.contains(.disk) && self.options.contains(.memory) {
                Task {
                    await self.cache?.removeAllAsync()
                    self.show(alertTitle: "删除成功")
                }
            } else if self.options.contains(.disk) {
                Task {
                    await self.cache?.diskCache.removeAllAsync()
                    self.show(alertTitle: "删除成功")
                }
            } else if self.options.contains(.memory) {
                Task {
                    self.cache?.memoryCache.removeAll()
                    self.show(alertTitle: "删除成功")
                }
            }
        }))
        buttonToRemoveAllAsync.backgroundColor = .gray
        view.addSubview(buttonToRemoveAllAsync)
    }
}
