//
//  Hasher+constantAccrossExecutions.swift
//  YYCache_Swift
//
//  Created by syt on 2022/10/9.
//

import Foundation

extension Hasher {
    private struct _State {
        private var v0: UInt64 = 0x736f6d6570736575
        private var v1: UInt64 = 0x646f72616e646f6d
        private var v2: UInt64 = 0x6c7967656e657261
        private var v3: UInt64 = 0x7465646279746573
        private var v4: UInt64 = 0
        private var v5: UInt64 = 0
        private var v6: UInt64 = 0
        private var v7: UInt64 = 0
    }

    static func constantAccrossExecutions() -> Hasher {
        let offset = MemoryLayout<Hasher>.size - MemoryLayout<_State>.size
        var hasher = Hasher()
        withUnsafeMutableBytes(of: &hasher) {
            $0.baseAddress?.storeBytes(of: _State(), toByteOffset: offset, as: _State.self)
        }
        return hasher
    }
}
