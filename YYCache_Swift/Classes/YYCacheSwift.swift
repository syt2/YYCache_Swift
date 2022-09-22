//
//  YYCacheSwift.swift
//  YYKitSwift
//
//  Created by syt on 2022/9/19.
//

import Foundation

public class YYCacheSwift {
    public let name: String
    public let memoryCache: YYMemoryCache
    public let diskCacheSwift: YYDiskCacheSwift
    
    public convenience init?(name: String) {
        guard !name.isEmpty,
              let cacheFolder = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return nil
        }
        let path = "\(cacheFolder)/\(name)"
        self.init(path: path)
    }
    
    public init?(path: String) {
        guard !path.isEmpty,
              let diskCacheSwift = YYDiskCacheSwift.instance(path: path) else {
            return nil
        }
        let name = NSString(string: path).lastPathComponent
        let memoryCache = YYMemoryCache()
        memoryCache.name = name
        self.name = name
        self.diskCacheSwift = diskCacheSwift
        self.memoryCache = memoryCache
    }
    
    public static func cache(name: String) -> YYCacheSwift? {
        YYCacheSwift(name: name)
    }
    
    public static func cache(path: String) -> YYCacheSwift? {
        YYCacheSwift(path: path)
    }
}

public extension YYCacheSwift {
    
    func containes(key: String) -> Bool {
        memoryCache.containsObject(forKey: key)
            || diskCacheSwift.contains(key: key)
    }
    
    func contains(key: String, completion: @escaping (String, Bool) -> Void) {
        if memoryCache.containsObject(forKey: key) {
            DispatchQueue.global().async {
                completion(key, true)
            }
        } else {
            diskCacheSwift.contains(key: key, completion: completion)
        }
    }
    
    func get<T>(type: T.Type, key: String) -> T? where T: Codable {
        if let object = memoryCache.object(forKey: key) as? T {
            return object
        }
        guard let object = diskCacheSwift.get(type: T.self, key: key) else {
            return nil
        }
        memoryCache.setObject(object, forKey: key)
        return object
    }
    
    func set<T>(key: String, value: T?) where T: Codable {
        memoryCache.setObject(value, forKey: key)
        diskCacheSwift.set(key: key, value: value)
    }
    
    
    func get<T>(type: T.Type, key: String, completion: @escaping (String, T?) -> Void) where T: Codable {
        if let object = memoryCache.object(forKey: key) as? T {
            DispatchQueue.global().async {
                completion(key, object)
            }
            return
        }
        diskCacheSwift.get(type: type, key: key) { key, value in
            if let value = value, !self.memoryCache.containsObject(forKey: key) {
                self.memoryCache.setObject(value, forKey: key)
            }
            completion(key, value)
        }
    }
    
    func set<T>(key: String, value: T?, completion: (() -> Void)?) where T: Codable {
        memoryCache.setObject(value, forKey: key)
        diskCacheSwift.set(key: key, value: value, completion: completion)
    }
    
    func remove(key: String) {
        memoryCache.removeObject(forKey: key)
        diskCacheSwift.remove(key: key)
    }
    
    func remove(key: String, completion: ((String) -> Void)?) {
        memoryCache.removeObject(forKey: key)
        diskCacheSwift.remove(key: key, completion: completion)
    }
    
    func removeAll() {
        memoryCache.removeAllObjects()
        diskCacheSwift.removeAll()
    }
    
    func removeAll(completion: (() -> Void)?) {
        memoryCache.removeAllObjects()
        diskCacheSwift.removeAll(completion: completion)
    }
    
    func removeAll(progressCallback: ((Int, Int) -> Void)?, completion: ((Bool) -> Void)?) {
        memoryCache.removeAllObjects()
        diskCacheSwift.removeAll(progressCallback: progressCallback, completion: completion)
    }
}


// MARK: objc nscoding get/set
public extension YYCacheSwift {
    func get<T>(type: T.Type, key: String) -> T? where T: NSObject, T: NSCoding {
        if let object = memoryCache.object(forKey: key) as? T {
            return object
        }
        guard let object = diskCacheSwift.get(type: T.self, key: key) else {
            return nil
        }
        memoryCache.setObject(object, forKey: key)
        return object
    }
    
    func set<T>(key: String, value: T?) where T: NSObject, T: NSCoding {
        memoryCache.setObject(value, forKey: key)
        diskCacheSwift.set(key: key, value: value)
    }
    
    func get<T>(type: T.Type, key: String, completion: @escaping (String, T?) -> Void) where T: NSObject, T: NSCoding {
        if let object = memoryCache.object(forKey: key) as? T {
            DispatchQueue.global().async {
                completion(key, object)
            }
            return
        }
        diskCacheSwift.get(type: type, key: key) { key, value in
            if let value = value, !self.memoryCache.containsObject(forKey: key) {
                self.memoryCache.setObject(value, forKey: key)
            }
            completion(key, value)
        }
    }
    
    func set<T>(key: String, value: T?, completion: (() -> Void)?) where T: NSObject, T: NSCoding {
        memoryCache.setObject(value, forKey: key)
        diskCacheSwift.set(key: key, value: value, completion: completion)
    }
}
