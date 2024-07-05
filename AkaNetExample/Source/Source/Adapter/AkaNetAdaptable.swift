//
//  AkaNetAdaptable.swift
//  AkaNet
//
//  Created by Sekitou on 2024/07/05.
//
//  AkaNet is an open-source framework based on Moya, licensed under the MIT License.
//
//  MIT License
//
//  Copyright (c) 2024 Sekitou
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import UIKit

public protocol AkaNetAdaptable {
    var app_id: Int { get }
    var user_id: Int { get }
    var idfa: String { get }
    var idfv: String { get }
    var ip_region: String? { get }
    var ip: String? { get }
    var device_id: String { get }
    var lane: String { get set }
    var releaseLane: String { get }
    
    var auth: NetworkAuthProtocol? { get }
    var defaultTimeoutMs: Int64 { get }
    var os_version: String { get }
    var defaultDomain: String { get }
    var defaultStreamingDomain: String { get }
    var defaultTestDomain: String { get }
    var dynamicIps: [String] { get }
    
    var requestPoolLimit: Int { get }
    
    func commonParams() -> [String: Any]
    
    
    func getAppVersion() -> String
    func getSyslanguage() -> String?
    func getRegion() -> String?
    func headerParams() -> [String: String]
    func streamingDomain() -> String
    func domain() -> String
    func getTimeOut(path: String?) -> Int
    func updateIpRegion(ip_region: String)
    func updateIp(ip: String)
}

extension AkaNetAdaptable {    

    public var app_id: Int {
        return 1
    }
    
    public var user_id: Int {
        return 0
    }
    
    public var idfa: String {
        return "0"
    }
    
    public var idfv: String {
        return "0"
    }
    
    
    public var ip_region: String? {
        return  ""
    }

    public var ip: String? {
        return  ""
    }
    
    public var device_id: String {
        return "0"
    }
    
    /// ppe 泳道
    public var lane: String {
        get {
            return  ""
        }
        set {
            
        }
        
    }
    
    public var releaseLane: String {
        return ""
    }
    
    
    public var auth: NetworkAuthProtocol? {
        nil
    }
    
    public var defaultTimeoutMs: Int64 {
        0
    }
    
    public var os_version: String {
        UIDevice.current.systemVersion
    }

    public var defaultDomain: String {
        return ""
    }
    
    public var defaultStreamingDomain: String {
        return ""
    }
    
    public var defaultTestDomain: String {
        return ""
    }
    
    public var dynamicIps: [String]{
        return []
    }
    
    public var disable_personalization: Bool {
        return false
    }
    
    public func commonParams() -> [String: Any] {
        return [:]
    }
    
    public var requestPoolLimit: Int {
        6
    }
    
    public func getAppVersion() -> String {
        let dic = Bundle.main.infoDictionary
        if let version = dic?["CFBundleShortVersionString"] as? String {
            return version
        } else {
            return "1.0.0"
        }
    }
    
    public func getSyslanguage() -> String? {
        let currentLocale = Locale.current
        return currentLocale.languageCode
    }
    
    public func getRegion() -> String? {
        let currentLocale = Locale.current
        return currentLocale.regionCode
    }
    
    /// 获取path的超时时间
    /// - Parameter path: 请求path
    /// - Returns: ms超时时间
    public func getTimeOut(path: String? = nil) -> Int{
        return Int(defaultTimeoutMs)
    }
    
    // 暂时不做测速或者ping，直接返回第一个
    public func domain() -> String {
        return ""
    }
    
    public func streamingDomain() -> String {
        return ""
    }
    
    public func mirrorDomain() -> String {
        return ""
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
    
    func updateIpRegion(ip_region: String) {
        
    }
    
    func updateIp(ip: String) {
        
    }
}

public struct AkaNetAdapter {
    struct netAdapter : AkaNetAdaptable {
        
    }
    public static let shared: AkaNetAdaptable = (AkaNetAdapter() as? AkaNetAdaptable) ?? netAdapter()
}
