//
//  Atomic.swift
//  NetworkService
//
//  Created by fushiguro on 2024/2/20.
//

import Foundation

@propertyWrapper
final class Atomic<Value> {
    private var lock: NSRecursiveLock = NSRecursiveLock()

    private var value: Value

    var wrappedValue: Value {
        get {
            lock.lock(); defer { lock.unlock() }
            return value
        }

        set {
            lock.lock(); defer { lock.unlock() }
            value = newValue
        }
    }

    init(wrappedValue value: Value) {
        self.value = value
    }
}
