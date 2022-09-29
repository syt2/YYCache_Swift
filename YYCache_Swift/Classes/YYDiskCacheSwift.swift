//
//  YYDiskCacheSwift.swift
//  YYKitSwift
//
//  Created by 沈庾涛 on 2022/9/18.
//

import Foundation
import UIKit
import CommonCrypto

public class YYDiskCacheSwift {
    public let path: URL
    public let inlineThreshold: UInt
    public var customFileNameBlock: ((String) -> String)?
    
    public var countLimit: UInt = .max
    public var costLimit: UInt = .max
    public var ageLimit: TimeInterval = .infinity
    public var freeDiskSpaceLimit: UInt = 0
    public var autoTrimInterval: TimeInterval = 60
    public var errorLogsEnabled: Bool = false
    
    private var kvStroage: YYKVStorageSwift?
    private var semaphore = DispatchSemaphore(value: 1)
    private var queue: DispatchQueue = DispatchQueue(label: "com.ibireme.cache.disk", attributes: .concurrent)
    
    private init(path: URL, inlineThreshold: UInt) {
        self.path = path
        self.inlineThreshold = inlineThreshold
        NotificationCenter.default.addObserver(self, selector: #selector(_appWillBeTerminated), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
    }
    
    public static func instance(path: URL, inlineThreshold: UInt = 20 * 1024) -> YYDiskCacheSwift? {
        if let globalCache = YYDiskCacheGetGlobal(path: path) {
            return globalCache
        }
        let type: YYKVStorageType
        switch inlineThreshold {
        case 0:
            type = .file
        case .max:
            type = .SQLite
        default:
            type = .mixed
        }
        guard let kv = YYKVStorageSwift(path: path, type: type) else {
            return nil
        }
        let instance = YYDiskCacheSwift(path: path, inlineThreshold: inlineThreshold)
        instance.kvStroage = kv
        instance._trimRecursively()
        YYDiskCacheSetGlobal(cache: instance)
        return instance
    }
}

public extension YYDiskCacheSwift {
    func contains(key: String) -> Bool {
        semaphore.around(kvStroage?.contains(key: key) ?? false)
    }
    
    func contains(key: String, completion: @escaping (String, Bool) -> Void) {
        queue.async { [weak self] in
            completion(key, self?.contains(key: key) ?? false)
        }
    }
    
    func get<T>(type: T.Type, key: String) -> T? where T: Codable {
        guard let item = semaphore.around(kvStroage?.getItem(key: key)), let data = item.value else { return nil }
        let object = try? JSONDecoder().decode(T.self, from: data)
        if let object = object, let extData = item.extendedData {
            Self.setExtendedData(extData, to: object)
        }
        return object
    }
    
    func get<T>(type: T.Type, key: String, completion: @escaping (String, T?) -> Void) where T: Codable {
        queue.async { [weak self] in
            completion(key, self?.get(type: type, key: key))
        }
    }
    
    func set<T>(key: String, value: T?) where T: Codable {
        guard let newValue = value else {
            remove(key: key)
            return
        }
        guard let value = try? JSONEncoder().encode(newValue) else { return }
        let extData = Self.getExtendedData(object: newValue)
        var filename: String? = nil
        if kvStroage?.type != .SQLite && value.count > inlineThreshold {
            filename = _filename(key: key)
        }
        semaphore.around {
            kvStroage?.saveItem(key: key, value: value, filename: filename, extendedData: extData)
        }
    }
    
    func set<T>(key: String, value: T?, completion: (() -> Void)?)  where T: Codable {
        queue.async { [weak self] in
            self?.set(key: key, value: value)
            completion?()
        }
    }
    
    func remove(key: String) {
        semaphore.around(kvStroage?.removeItem(key: key))
    }
    
    func remove(key: String, completion: ((String) -> Void)?) {
        queue.async { [weak self] in
            self?.remove(key: key)
            completion?(key)
        }
    }
    
    func removeAll() {
        semaphore.around(kvStroage?.removeAllItems())
    }
    
    func removeAll(completion: (() -> Void)?) {
        queue.async { [weak self] in
            self?.removeAll()
            completion?()
        }
    }
    
    func removeAll(progressCallback: ((Int, Int) -> Void)?, completion: ((Bool) -> Void)?) {
        queue.async { [weak self] in
            guard let self = self else {
                completion?(true)
                return
            }
            self.semaphore.around {
                self.kvStroage?.removeAllItems {
                    progressCallback?(Int($0), Int($1))
                } completion: {
                    completion?($0)
                }
            }
        }
    }
    
    var totalCount: Int {
        Int(semaphore.around(kvStroage?.count) ?? 0)
    }
    
    func totalCount(completion: @escaping (Int) -> Void) {
        queue.async { [weak self] in
            completion(self?.totalCount ?? 0)
        }
    }
    
    var totalCost: Int {
        Int(semaphore.around(kvStroage?.size) ?? 0)
    }
    
    func totalCost(completion: @escaping (Int) -> Void) {
        queue.async { [weak self] in
            completion(self?.totalCost ?? 0)
        }
    }
    
    var errorLogsEnable: Bool {
        get {
            semaphore.around(kvStroage?.errorLogsEnabled ?? false)
        }
        set {
            semaphore.around(kvStroage?.errorLogsEnabled = newValue)
        }
    }
}


// MARK: objc nscoding get/set
public extension YYDiskCacheSwift {
    func get<T>(type: T.Type, key: String) -> T? where T: NSObject, T: NSCoding {
        guard let item = semaphore.around(kvStroage?.getItem(key: key)), let data = item.value else { return nil }
        let object = try? NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: data)
        if let object = object, let extData = item.extendedData {
            Self.setExtendedData(extData, to: object)
        }
        return object
    }
    
    func get<T>(type: T.Type, key: String, completion: @escaping (String, T?) -> Void) where T: NSObject, T: NSCoding {
        queue.async { [weak self] in
            completion(key, self?.get(type: type, key: key))
        }
    }
    
    func set<T>(key: String, value: T?) where T: NSObject, T: NSCoding {
        guard let newValue = value else {
            remove(key: key)
            return
        }
        
        guard let value = try? NSKeyedArchiver.archivedData(withRootObject: T.self, requiringSecureCoding: false) else { return }
        let extData = Self.getExtendedData(object: newValue)
        var filename: String? = nil
        if kvStroage?.type != .SQLite && value.count > inlineThreshold {
            filename = _filename(key: key)
        }
        semaphore.around {
            kvStroage?.saveItem(key: key, value: value, filename: filename, extendedData: extData)
        }
    }
    
    func set<T>(key: String, value: T?, completion: (() -> Void)?) where T: NSObject, T: NSCoding {
        queue.async { [weak self] in
            self?.set(key: key, value: value)
            completion?()
        }
    }
}


// MARK: trim
public extension YYDiskCacheSwift {
    func trim(count: UInt) {
        semaphore.around {
            _trim(count: count)
        }
    }
    
    func trim(count: UInt, completion: (() -> Void)?) {
        queue.async { [weak self] in
            self?._trim(count: count)
            completion?()
        }
    }

    func trim(cost: UInt) {
        semaphore.around {
            _trim(cost: cost)
        }
    }
    
    func trim(cost: UInt, completion: (() -> Void)?) {
        queue.async { [weak self] in
            self?._trim(cost: cost)
            completion?()
        }
    }
    
    func trim(age: TimeInterval) {
        semaphore.around {
            _trim(age: age)
        }
    }
    
    func trim(age: TimeInterval, completion: (() -> Void)?) {
        queue.async { [weak self] in
            self?._trim(age: age)
            completion?()
        }
    }
}


// MARK: extened data
public extension YYDiskCacheSwift {
    private struct AssociateKey {
        static var extendedDataKey = "extendedDataKey"
    }
    
    static func getExtendedData(object: Any?) -> Data? {
        guard let object = object else { return nil }
        return objc_getAssociatedObject(object, &AssociateKey.extendedDataKey) as? Data
    }
    
    static func setExtendedData(_ data: Data?, to object: Any?) {
        guard let object = object else { return }
        objc_setAssociatedObject(object, &AssociateKey.extendedDataKey, data, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}


// MARK: global instance
private extension YYDiskCacheSwift {
    private static let globalInstancesLock = DispatchSemaphore(value: 1)
    private static var globalInstances = [String: () -> YYDiskCacheSwift?]()
    
    static func YYDiskCacheGetGlobal(path: URL) -> YYDiskCacheSwift? {
        return globalInstancesLock.around(globalInstances[path.absoluteString]?())
    }
    
    static func YYDiskCacheSetGlobal(cache: YYDiskCacheSwift?) {
        guard let path = cache?.path else { return }
        globalInstancesLock.around {
            guard let cache = cache else {
                globalInstances.removeValue(forKey: path.absoluteString)
                return
            }
            globalInstances[path.absoluteString] = { [weak cache] in cache }
        }
    }
    
    private static func YYStringSHA256(string: String) -> String {
        let data = Data(string.utf8)
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private static func YYDiskSpaceFree() -> UInt? {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        let values = try? fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        guard let capacity = values?.volumeAvailableCapacity, capacity >= 0 else { return nil }
        return UInt(capacity)
    }
}


// MARK: private
private extension YYDiskCacheSwift {
    func _trimRecursively() {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + autoTrimInterval) { [weak self] in
            guard let self = self else { return }
            self._trimInBackground()
            self._trimRecursively()
        }
    }
    
    func _trimInBackground() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.semaphore.around {
                self._trim(cost: self.costLimit)
                self._trim(count: self.countLimit)
                self._trim(age: self.ageLimit)
                self._trim(freeDiskSpace: self.freeDiskSpaceLimit)
            }
        }
    }
    
    func _trim(cost: UInt) {
        guard costLimit < .max else { return }
        kvStroage?.removeItems(toFitSize: Int(cost))
    }
    
    func _trim(count: UInt) {
        guard countLimit < .max else { return }
        kvStroage?.removeItems(toFitCount: Int(count))
    }
    
    func _trim(age: TimeInterval) {
        guard age > 0 else {
            kvStroage?.removeAllItems()
            return
        }
        let timestamp = TimeInterval(time(nil))
        guard timestamp > ageLimit else { return }
        let age = Int32(timestamp - ageLimit)
        guard age < .max else { return }
        kvStroage?.removeItems(earlierThanTime: Int(age))
    }
    
    func _trim(freeDiskSpace: UInt) {
        guard freeDiskSpace != 0 else { return }
        guard let totalBytes = kvStroage?.size, totalBytes > 0 else { return }
        guard let diskFreeBytes = Self.YYDiskSpaceFree() else { return }
        let needTrimBytes = freeDiskSpace - diskFreeBytes
        guard needTrimBytes > 0 else { return }
        let costLimit = max(0, UInt(totalBytes) - needTrimBytes)
        _trim(cost: costLimit)
    }
    
    func _filename(key: String) -> String? {
        return customFileNameBlock?(key) ?? Self.YYStringSHA256(string: key)
    }
    
    @objc func _appWillBeTerminated() {
        semaphore.around {
            kvStroage = nil
        }
    }
}
