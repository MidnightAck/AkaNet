

import Foundation
import HandyJSON
import Combine

public class MoyaService: NSObject {
    public static let shared: MoyaService = MoyaService()
    
    public lazy var provider = MoyaProvider<MultiTarget>(
        endpointClosure: MoyaProvider.mnmEndpointMapping,
        requestClosure: MoyaProvider<MultiTarget>.mnmRequestMapping,
        session: MoyaProvider<MultiTarget>.mnmAlamofireSession(),
        plugins: [LogPlugin()])
    
    // 请求池上限
    public static let requestPoolLimit = AkaNetAdapter.shared.requestPoolLimit
    // 当前活跃的请求数量
    public static var activeRequests = 0
    // 等待执行的请求队列
    public static var waitingRequestsQueue: [(() -> Void, RequestPriority)] = []
    // 用于同步访问的队列
    public static let synchronizationQueue = DispatchQueue(label: "com.myService.synchronizationQueue")
    
    private let ips: [String] = AkaNetAdapter.shared.dynamicIps
    
    private var currentPickIdx: Int = 0
    private var runOut: Bool = false
    
    public func switchConfig() {
        if currentPickIdx == ips.count - 1 {
            runOut = true
            return
        }
        currentPickIdx = (currentPickIdx + 1) % (ips.count + 1)
    }
    
    public func getConfig() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        if currentPickIdx != 0, !runOut {
            config.connectionProxyDictionary = [
                kCFNetworkProxiesHTTPEnable as AnyHashable: true,
                kCFNetworkProxiesHTTPProxy as AnyHashable: ips[currentPickIdx] ,
                kCFNetworkProxiesHTTPPort as AnyHashable: 443,
            ]
        }
        return config

    }
    
    public func updateSession() {
        switchConfig()
        let configuration = getConfig()
        
        provider = MoyaProvider<MultiTarget>(
            endpointClosure: MoyaProvider.mnmEndpointMapping,
            requestClosure: MoyaProvider<MultiTarget>.mnmRequestMapping,
            session: Session(configuration: configuration, startRequestsImmediately: false),
            plugins: [LogPlugin()])
    }

}
