//
//  YYMemoryCacheSwift.swift
//  YYKitSwift
//
//  Created by 沈庾涛 on 2022/9/18.
//

import Foundation

class YYMemoryCacheSwift {
    var name: String?
    private(set) var titalCount: UInt = 0
    private(set) var totalCost: UInt = 0

    var countLimit: UInt = .max
    var costLimit: UInt = .max
    var ageLimit: TimeInterval = .infinity
    var autoTrimInterval: TimeInterval = 5
    var shouldRemoveAllObjectsOnMemoryWarning: Bool = true
    var shouldRemoveAllObjectsWhenEnteringBackground: Bool = true
    var didReceiveMemoryWarningClosure: ((YYMemoryCacheSwift) -> Void)?
    var didEnterBackgroundClosure: ((YYMemoryCacheSwift) -> Void)?
    
    private var lock = pthread_mutex_t()
    private var lru = YYLinkMap()
    private var queue = DispatchQueue(label: "com.ibireme.cache.memory")
    
    init() {
        pthread_mutex_init(&lock, nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidReceiveMemoryWarningNotification), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
        trimRecursively()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        lru.removeAll()
        pthread_mutex_destroy(&lock)
    }
    
    var count: UInt {
        around(lru.totalCount)
    }
    
    var cost: UInt {
        around(lru.totalCost)
    }

    func contains(key: AnyHashable) -> Bool {
        around(lru.dict.keys.contains(key))
    }

    subscript(key: AnyHashable) -> Any? {
        set { update(value: newValue, forKey: key) }
        get { get(key: key) }
    }
    
    func get(key: AnyHashable) -> Any? {
        around {
            guard let node = lru.dict[key] else { return nil }
            node.time = CACurrentMediaTime()
            lru.bringToHead(node: node)
            return node.value
        }
    }

    func update(value: Any?, forKey key: AnyHashable, cost: UInt = 0) {
        guard let value = value else {
            remove(forKey: key)
            return
        }
        around {
            let now = CACurrentMediaTime()
            if let node = lru.dict[key] {
                lru.totalCost -= node.cost
                lru.totalCost += cost
                node.cost = cost
                node.time = now
                node.value = value
                lru.bringToHead(node: node)
            } else {
                let node = YYLinkedMapNode(key: key, value: value, cost: cost, time: now)
                lru.insertAtHead(node: node)
            }
            if lru.totalCost > costLimit {
                queue.async { self._trim(cost: self.costLimit) }
            }
            if lru.totalCount > countLimit {
                lru.removeTail()
            }
        }
    }

    func remove(forKey key: AnyHashable) {
        around {
            guard let node = lru.dict[key] else { return }
            lru.remove(node: node)
        }
    }

    func removeAll() {
        around(lru.removeAll())
    }
}

// MARK: trim
extension YYMemoryCacheSwift {
    func trim(count: UInt) {
        _trim(count: count)
    }

    func trim(cost: UInt) {
        _trim(cost: cost)
    }

    func trim(age: TimeInterval) {
        _trim(age: age)
    }
}


private extension YYMemoryCacheSwift {
    func trimRecursively() {
        DispatchQueue.global().asyncAfter(deadline: .now() + autoTrimInterval) { [weak self] in
            guard let self = self else { return }
            self.trimInBackground()
            self.trimRecursively()
        }
    }
    
    func trimInBackground() {
        queue.async {
            self._trim(cost: self.costLimit)
            self._trim(count: self.countLimit)
            self._trim(age: self.ageLimit)
        }
    }
    
    func _trim(cost: UInt) {
        var finish: Bool = around {
            guard costLimit > 0 else {
                lru.removeAll()
                return true
            }
            return lru.totalCost <= costLimit
        }
        if finish { return }
        
        repeat {
            if pthread_mutex_trylock(&lock) == 0 {
                if lru.totalCost > costLimit {
                    lru.removeTail()
                } else {
                    finish = true
                }
                pthread_mutex_unlock(&lock)
            } else {
                usleep(10 * 1000)
            }
        } while !finish
    }
    
    func _trim(count: UInt) {
        var finish: Bool = around {
            guard countLimit > 0 else {
                lru.removeAll()
                return true
            }
            return lru.totalCount <= countLimit
        }
        if finish { return }
        
        repeat {
            if pthread_mutex_trylock(&lock) == 0 {
                if lru.totalCount > countLimit {
                    lru.removeTail()
                } else {
                    finish = true
                }
                pthread_mutex_unlock(&lock)
            } else {
                usleep(10 * 1000)
            }
        } while !finish
    }

    func _trim(age: TimeInterval) {
        let now = CACurrentMediaTime()
        var finish: Bool = around {
            guard ageLimit > 0 else {
                lru.removeAll()
                return true
            }
            guard let tail = lru.tail else { return true }
            return now - tail.time <= ageLimit
        }
        if finish { return }
        repeat {
            if pthread_mutex_trylock(&lock) == 0 {
                if let tail = lru.tail, now - tail.time > ageLimit {
                    lru.removeTail()
                } else {
                    finish = true
                }
                pthread_mutex_unlock(&lock)
            } else {
                usleep(10 * 1000)
            }
        } while !finish
    }
    
    @objc func appDidReceiveMemoryWarningNotification() {
        didReceiveMemoryWarningClosure?(self)
        if shouldRemoveAllObjectsOnMemoryWarning {
            removeAll()
        }
    }
    
    @objc func appDidEnterBackgroundNotification() {
        didEnterBackgroundClosure?(self)
        if shouldRemoveAllObjectsWhenEnteringBackground {
            removeAll()
        }
    }
}


private extension YYMemoryCacheSwift {
    @discardableResult
    func around<T>(_ closure: () throws -> T) rethrows -> T {
        pthread_mutex_lock(&lock)
        defer { pthread_mutex_unlock(&lock) }
        return try closure()
    }
    
    @discardableResult
    func around<T>(_ closure: @autoclosure () throws -> T) rethrows -> T {
        pthread_mutex_lock(&lock)
        defer { pthread_mutex_unlock(&lock) }
        return try closure()
    }
}

class YYLinkedMapNode {
    weak var prev: YYLinkedMapNode?
    weak var next: YYLinkedMapNode?
    var key: AnyHashable
    var value: Any
    var cost: UInt
    var time: TimeInterval
    
    init(key: AnyHashable, value: Any, cost: UInt = 0, time: TimeInterval = CACurrentMediaTime()) {
        self.key = key
        self.value = value
        self.cost = cost
        self.time = time
    }
}

extension YYLinkedMapNode: Hashable {
    static func == (lhs: YYLinkedMapNode, rhs: YYLinkedMapNode) -> Bool {
        lhs.key == rhs.key
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}


class YYLinkMap {
    var dict: [AnyHashable: YYLinkedMapNode]
    var totalCost: UInt = 0
    var totalCount: UInt = 0
    weak var head: YYLinkedMapNode?
    weak var tail: YYLinkedMapNode?

    init() {
        dict = [:]
    }

    func insertAtHead(node: YYLinkedMapNode) {
        dict[node.key] = node
        totalCost += node.cost
        totalCount += 1
        node.next = head
        head?.prev = node
        head = node
        if tail == nil { tail = node }
    }

    func bringToHead(node: YYLinkedMapNode) {
        guard head != node else { return }
        node.next?.prev = node.prev
        node.prev?.next = node.next
        if tail == node { tail = node }
        node.prev = nil
        node.next = head
        head?.prev = node
        head = node
    }

    func remove(node: YYLinkedMapNode) {
        dict.removeValue(forKey: node.key)
        totalCost -= node.cost
        totalCount -= 1
        node.next?.prev = node.prev
        node.prev?.next = node.next
        if head == node { head = node.next }
        if tail == node { tail = node.prev }
    }

    @discardableResult
    func removeTail() -> YYLinkedMapNode? {
        guard let tail = tail else { return nil }
        remove(node: tail)
        return tail
    }

    func removeAll() {
        totalCost = 0
        totalCount = 0
        head = nil
        tail = nil
        dict.removeAll()
    }
}
