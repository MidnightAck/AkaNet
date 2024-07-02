

import Foundation

public protocol AkaNetLogAdaptable {
    var logPath: [String] { get }
    func log(custom: [String: Any])
}

extension AkaNetLogAdaptable {
    var logPath: [String] {
        [""]
    }
    
    func log(custom: [String: Any]) {}

}

public struct AkaNetLogAdapter {
    struct netLogAdapter : AkaNetLogAdaptable {}
    static let shared: AkaNetLogAdaptable = (AkaNetLogAdapter() as? AkaNetLogAdaptable) ?? netLogAdapter()
}
