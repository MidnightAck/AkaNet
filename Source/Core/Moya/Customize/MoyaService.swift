//
//  MoyaService.swift
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
