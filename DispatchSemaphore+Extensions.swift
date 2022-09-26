//
//  DispatchSemaphore+Extensions.swift
//  YYCache_Swift
//
//  Created by syt on 2022/9/26.
//

import Foundation

extension DispatchSemaphore {
    @discardableResult
    func around<T>(_ closure: () throws -> T) rethrows -> T {
        wait()
        defer { signal() }
        return try closure()
    }
    
    @discardableResult
    func around<T>(_ closure: @autoclosure () throws -> T) rethrows -> T {
        wait()
        defer { signal() }
        return try closure()
    }
    
    func around(_ closure: @autoclosure () throws -> Void) rethrows -> Void {
        wait()
        defer { signal() }
        return try closure()
    }

    func around(_ closure: () throws -> Void) rethrows -> Void {
        wait()
        defer { signal() }
        return try closure()
    }
}
