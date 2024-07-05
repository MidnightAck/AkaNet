//
//  AkaNetAdapter+Biz.swift
//  AkaNetExample
//
//  Created by fushiguro on 2024/7/5.
//

import Foundation
import AkaNet
import UIKit

public let kDomainListKey = "weaver.networkConfig.domainList"
public let kCustomRulesKey = "weaver.networkConfig.customRules"
public let kDefaultTimeoutKey = "weaver.networkConfig.defaultTimeout"
public let kDefaultDomain = "https://m.belloai.cn"

public let AUTH_TOKEN = "auth_token"
public let REFRESH_TOKEN = "refresh_token"
public let USER_ID = "user_id"
public var IDFAKEY:String = "WEAVER_IDFA"
public var IDFVKEY:String = "WEAVER_IDFV"
public var UUIDKEY:String = "WEAVER_UUID"
public let DEVICE_ID = "device_id"
public let LANE = "ppe_lane"
public let TEEN_MODE = "TeenModeManager.dialogKey"

extension AkaNetAdapter: AkaNetAdaptable {
    public var app_id: Int {
        return AkaNetConfig.shared.appId
    }

    public var user_id: Int {
        return UserDefaults.standard.integer(forKey: USER_ID)
    }
    
    public var ip_region: String? {
        ""
    }
    
    public var ip: String? {
        ""
    }
    
    public var debug_ip_region: String? {
        ""
    }
    
    public var idfa: String {
        return ""
    }
        
    public var idfv: String {
        return ""
    }
    
    public var device_id: String {
        return "0"
    }
    
    public var requestPoolLimit: Int {
        6
    }
    
    public var lane: String {
        get {
            AkaNetConfig.shared.lane
        }
        set {
            UserDefaults.standard.set(newValue, forKey: LANE)
        }
        
    }
    
    public var releaseLane: String {
        return (Bundle.main.infoDictionary?["CFNetworkLane"] as? String) ?? ""
    }
    
    public var auth: NetworkAuthProtocol? {
        AkaNetConfig.shared.auth
    }
    
    public var defaultTimeoutMs: Int64 {
        AkaNetConfig.shared.defaultTimeoutMs
    }
    
    public var os_version: String {
        UIDevice.current.systemVersion
    }

    public var defaultDomain: String {
        return AkaNetConfig.shared.defaultDomain
    }
    
    public var defaultStreamingDomain: String {
        return AkaNetConfig.shared.defaultStreamingDomain
    }
    
    public var defaultTestDomain: String {
        return AkaNetConfig.shared.defaultTestDomain
    }
    
    public var dynamicIps: [String]{
        return AkaNetConfig.shared.dynamicIps
    }

    
    public func commonParams() -> [String: Any] {
        var common_params = auth?.common_params ?? [:]
        common_params["os"] = 1
        common_params["device_platform"] = "ios"
        common_params["request_lib"] = "native"
        common_params["sys_language"] = Locale.preferredLanguages.first
        common_params["sys_region"] = getRegion() ?? ""
        if let ip_region = ip_region {
            common_params["ip_region"] = ip_region
        }
        if let debug_ip_region = debug_ip_region, debug_ip_region.isEmpty == false {
            common_params["ip_region"] = debug_ip_region
        }
        common_params["app_id"] = app_id
        common_params["os_version"] = os_version
        common_params["brand"] = "apple"
//        common_params["network_type"] = NetworkTypeManager.getNetworkType()
        return common_params
    }
    
    
    /// 获取path的超时时间
    /// - Parameter path: 请求path
    /// - Returns: ms超时时间
    public func getTimeOut(path: String? = nil) -> Int{
        return Int(defaultTimeoutMs)
    }
    
    // 暂时不做测速或者ping，直接返回第一个
    public func domain() -> String {
        return defaultDomain
    }
    
    public func streamingDomain() -> String {
        return defaultStreamingDomain
    }
    
    public func headerParams() -> [String: String] {
        var headers = auth?.auth_headers ?? [:]
#if DEBUG
        headers["Lane"] = lane
#else
        if !releaseLane.isEmpty {
            headers["Lane"] = releaseLane
        }
#endif
        return headers
    }
    
    public func updateIpRegion(ip_region: String) {
        
    }
    
    public func updateIp(ip: String) {
        
    }

}
