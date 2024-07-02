//
//  Cancellable.swift
//  NetworkService
//
//  Created by fushiguro on 2024/2/20.
//

/// Protocol to define the opaque type returned from a request.
public protocol MoyaCancellable {

    /// A Boolean value stating whether a request is cancelled.
    var isCancelled: Bool { get }

    /// Cancels the represented request.
    func cancel()
}

internal class CancellableWrapper: MoyaCancellable {
    internal var innerCancellable: MoyaCancellable = SimpleCancellable()

    var isCancelled: Bool { innerCancellable.isCancelled }

    internal func cancel() {
        innerCancellable.cancel()
    }
}

internal class SimpleCancellable: MoyaCancellable {
    var isCancelled = false
    func cancel() {
        isCancelled = true
    }
}
