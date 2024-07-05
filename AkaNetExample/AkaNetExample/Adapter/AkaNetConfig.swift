//
//  AkaNetConfig.swift
//  AkaNetExample
//
//  Created by fushiguro on 2024/7/5.
//

import Foundation
import AkaNet
import UIKit

public class AkaNetConfig: NSObject {
    public var auth: NetworkAuthProtocol?
    public var releaseLane: String = ""
    public var appId: Int = 0
    public var device_id: String = ""
    public var defaultTimeoutMs: Int64 = 60000
    public let os_version = UIDevice.current.systemVersion

    public var defaultDomain = "https://"
    public var defaultStreamingDomain = ""
    public var defaultTestDomain = "https://"
    
    public var defaultWebsocketDomain = ""
    public var defaultWebsocketTestDomain = ""

    public var dynamicIps: [String] = []
        
    public var refresh_token: String {
        return UserDefaults.standard.string(forKey: REFRESH_TOKEN) ?? ""
    }
    
    
    public var lane: String {
        get {
            return UserDefaults.standard.string(forKey: LANE) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: LANE)
        }
        
    }
    
    static public let shared: AkaNetConfig = AkaNetConfig()

    override init() {
        self.defaultTimeoutMs = 60 * 1000
        
        super.init()
    }
    
    public func domain() -> String {
        return defaultDomain
    }
    
    public func streamingDomain() -> String {
        return defaultStreamingDomain
    }

    public func websocketDomain() -> String {
        return defaultWebsocketDomain
    }
}
