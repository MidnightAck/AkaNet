
import Foundation
import HandyJSON
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
    var domainList: [Domain] { get }
    
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

    public var domainList:[Domain] {
        return []
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


public struct Domain: HandyJSON {
    public init() {
        
    }
    
    public init(host: String?) {
        self.host = host
    }
    public var host: String?
}
