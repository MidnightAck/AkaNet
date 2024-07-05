//
//  NetworkService.swift
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

class NetworkService: NSObject {
    static let shared = NetworkService()
    
    private var cancellables: Set<AnyCancellable> = []
    private var isRefreshingToken = false
    private var pendingRequests: [RetryRequest] = []
    private let serialQueue = DispatchQueue(label: "com.networkService.serialQueue")
    
    private override init() {
        super.init()
    }
    
    public func GET(address: String, params: [String: Any]?, priority: RequestPriority, domainType: DomianType = .normal, block: @escaping CompleteBlock) {
        let request = MultiTarget(AkaBasicMoyaAPI.get(url: address, params: params ?? [:], domainType: domainType))
        sendRequest(target: request, priority: priority, block: block)
    }
    
    public func POST(address: String, params: [String: Any], priority: RequestPriority, domainType: DomianType = .normal, block: @escaping CompleteBlock) {
        let request = MultiTarget(AkaBasicMoyaAPI.post(url: address, params: params, domainType: domainType))
        sendRequest(target: request, priority: priority, block: block)
    }
    
    public func sendRequest(target: MultiTarget, priority: RequestPriority, retryCount: Int = 3, block: @escaping CompleteBlock) {
        serialQueue.async {
            self._sendRequest(target: target, priority: priority, retryCount: retryCount, block: block)
        }
    }
        
    private func _sendRequest(target: MultiTarget, priority: RequestPriority, retryCount: Int, block: @escaping CompleteBlock) {
        if isRefreshingToken {
            pendingRequests.append(.init(request: target, priorty: priority, completion: block))
            return
        }
        MoyaService.shared.provider.requestPublisher(target, priority: priority).sink {[weak self] completion in
            guard let self else { return }
            self.serialQueue.async {
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                    let (errorCode, errorString) = self.handleRequestFail(from: error)
                    if (errorCode == -1009 || errorCode == -1005 || errorCode == -1001), retryCount > 0 {
                        self.sendRequest(target: target, priority: priority, retryCount: retryCount - 1, block: block)
                        return
                    }
                    DispatchQueue.main.async {
                        block(["base_resp":["status_code": errorCode, "status_msg": errorString] as [String : Any]])
                    }
                }
            }
        } receiveValue: {[weak self] response in
            guard let self else { return }
            self.serialQueue.async {
                
                do {
                    if response.statusCode == NSURLErrorDNSLookupFailed {
                        MoyaService.shared.updateSession()
                        return
                    }
                    var res = try response.mapJSON() as? Dictionary<String,Any>
                    var base_resp = res?["base_resp"] as? [String: Any]
                    let trace_id = response.response?.headers.dictionary["trace-id"]
                    
                    if let ip_region = response.response?.headers.dictionary["X-Ip-Region"] as? String {
                        let origin_ip_region = AkaNetAdapter.shared.ip_region
                        if origin_ip_region != ip_region {
                            AkaNetAdapter.shared.updateIpRegion(ip_region: ip_region)
                        }
                    }
                    if let ip_region = response.response?.headers.dictionary["x-ip-region"] as? String {
                        let origin_ip_region = AkaNetAdapter.shared.ip_region
                        if origin_ip_region != ip_region {
                            AkaNetAdapter.shared.updateIpRegion(ip_region: ip_region)
                        }
                    }
                    
                    if let ip = response.response?.headers.dictionary["X-Ip"] as? String {
                        let origin_ip = AkaNetAdapter.shared.ip
                        if origin_ip != ip {
                            AkaNetAdapter.shared.updateIp(ip: ip)
                        }
                    }
                    if let ip = response.response?.headers.dictionary["x-ip"] as? String {
                        let origin_ip = AkaNetAdapter.shared.ip
                        if origin_ip != ip {
                            AkaNetAdapter.shared.updateIp(ip: ip)
                        }
                    }
                    base_resp?["trace_id"] = trace_id
                    res?["trace_id"] = trace_id
                    res?["base_resp"] = base_resp
                    DispatchQueue.main.async {
                        block(res ?? [:])
                    }
                    if MoyaService.activeRequests == 0 {
                        self.cancellables = []
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        block(["base_resp":["status_code":-1,"status_msg":"Network error"] as [String : Any]])
                    }
                }
            }
        }.store(in: &cancellables)


    }
    
    private func handleRequestFail(from error: MoyaError) -> (Int, String){
        switch error {
        case .underlying(let underlyingError, _):
            if let nsError = underlyingError.asAFError?.underlyingError as NSError?{
                return (nsError.code, nsError.localizedDescription)
            } else {
                return (error.errorCode, error.localizedDescription)
            }
        default:
            return (error.errorCode, error.localizedDescription)
        }
    }
    
    private func handlePendingRequests() {
        for request in pendingRequests {
            sendRequest(target: request.request, priority: request.priorty, block: request.completion)
        }
        pendingRequests.removeAll()
    }
    private func dropPendingRequests(error: [String: Any]) {
        for request in pendingRequests {
            request.completion(error)
        }
        pendingRequests.removeAll()
    }
    
}


private struct RetryRequest {
    let request: MultiTarget
    let priorty: RequestPriority
    let completion: CompleteBlock
}

public class AkaBasicMoyaPlugin: PluginType {
    init() {
        
    }
    
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        
        return request
    }
}
