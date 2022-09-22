//
//  UnfairLock.swift
//  Kaoan
//
//  Created by syt on 2022/8/11.
//

import Foundation

final public class UnfairLock {
    private let unfairLock: os_unfair_lock_t

    public init() {
        unfairLock = .allocate(capacity: 1)
        unfairLock.initialize(to: os_unfair_lock())
    }

    deinit {
        unfairLock.deinitialize(count: 1)
        unfairLock.deallocate()
    }

    private func lock() {
        os_unfair_lock_lock(unfairLock)
    }

    private func unlock() {
        os_unfair_lock_unlock(unfairLock)
    }
    
    @discardableResult
    public func around<T>(_ closure: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try closure()
    }
    
    @discardableResult
    public func around<T>(_ closure: @autoclosure () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try closure()
    }
    
    public func around(_ closure: @autoclosure () throws -> Void) rethrows -> Void {
        lock()
        defer { unlock() }
        return try closure()
    }

    public func around(_ closure: () throws -> Void) rethrows -> Void {
        lock()
        defer { unlock() }
        return try closure()
    }
}
