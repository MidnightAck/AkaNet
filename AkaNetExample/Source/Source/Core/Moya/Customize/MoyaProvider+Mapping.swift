//
//  MoyaProvider+Mapping.swift
//  NetworkService
//
//  Created by fushiguro on 2024/2/22.
//

import Foundation
import Alamofire
import CommonCrypto

public extension MoyaProvider {
    final class func mnmEndpointMapping(for target: Target) -> Endpoint {
        Endpoint(
            url: URL(target: target).absoluteString,
            sampleResponseClosure: { .networkResponse(200, target.sampleData) },
            method: target.method,
            task: target.task,
            httpHeaderFields: target.headers,
            bodyParams: target.bodyParams
        )
    }

    final class func mnmRequestMapping(for endpoint: Endpoint, closure: RequestResultClosure) {
        do {
            let urlRequest = try endpoint.mnmUrlRequest()
            closure(.success(urlRequest))
        } catch MoyaError.requestMapping(let url) {
            closure(.failure(MoyaError.requestMapping(url)))
        } catch MoyaError.parameterEncoding(let error) {
            closure(.failure(MoyaError.parameterEncoding(error)))
        } catch {
            closure(.failure(MoyaError.underlying(error, nil)))
        }
    }

    final class func mnmAlamofireSession() -> Session {
        let configuration = MoyaService.shared.getConfig()
        return Session(configuration: configuration, startRequestsImmediately: false)
    }
    
}


public extension Endpoint {
    func mnmUrlRequest() throws -> URLRequest {
        guard let requestURL = Foundation.URL(string: url) else {
            throw MoyaError.requestMapping(url)
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = httpHeaderFields
        request.timeoutInterval = TimeInterval(AkaNetAdapter.shared.getTimeOut(path: url) / 1000)
        
        let keys = method == HTTPMethod.get ? Array(bodyParams.keys) : Array(AkaNetAdapter.shared.commonParams().keys)
        let sortedKeys = keys.sorted()
        let paramStringList = sortedKeys.map { key in
            let string = String(format:"%@=%@",key,String(describing: method == HTTPMethod.get ? bodyParams[key] ?? "" : AkaNetAdapter.shared.commonParams()[key] ?? ""))
            return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
        }
        var signString:String = paramStringList.joined(separator: "&")
        if method == HTTPMethod.post {
            do{
                let jsonData = try JSONSerialization.data(withJSONObject: bodyParams, options: [])
                let jsonString = String(data: jsonData, encoding: .utf8)
                signString += jsonString ?? ""
            } catch {
                print("Error converting dictionary to JSON string: \(error.localizedDescription)")
            }
        }
        let timeStamp = String(Int(Date().timeIntervalSince1970))
        signString += "x-timestamp=" + timeStamp
        signString = signString.removingPercentEncoding ?? signString
        let sign = sha1SaltEncrypt(signString, salt: "salt=987c331b")
        var header = httpHeaderFields
        header?["x-timestamp"] = timeStamp
        header?["x-sign"] = sign
        if let ip_region = AkaNetAdapter.shared.ip_region {
            header?["ip_region"] = ip_region
        }
        if let sys_region = Locale.current.regionCode {
            header?["sys_region"] = sys_region
        }
        request.allHTTPHeaderFields = header
        
        
        
        switch task {
        case .requestPlain, .uploadFile, .uploadMultipart, .downloadDestination:
            return request
        case .requestData(let data):
            request.httpBody = data
            return request
        case let .requestJSONEncodable(encodable):
            return try request.encoded(encodable: encodable)
        case let .requestCustomJSONEncodable(encodable, encoder: encoder):
            return try request.encoded(encodable: encodable, encoder: encoder)
        case let .requestParameters(parameters, parameterEncoding):
            return try request.encoded(parameters: parameters, parameterEncoding: parameterEncoding)
        case let .uploadCompositeMultipart(_, urlParameters):
            let parameterEncoding = URLEncoding(destination: .queryString)
            return try request.encoded(parameters: urlParameters, parameterEncoding: parameterEncoding)
        case let .downloadParameters(parameters, parameterEncoding, _):
            return try request.encoded(parameters: parameters, parameterEncoding: parameterEncoding)
        case let .requestCompositeData(bodyData: bodyData, urlParameters: urlParameters):
            request.httpBody = bodyData
            let parameterEncoding = URLEncoding(destination: .queryString)
            return try request.encoded(parameters: urlParameters, parameterEncoding: parameterEncoding)
        case let .requestCompositeParameters(bodyParameters: bodyParameters, bodyEncoding: bodyParameterEncoding, urlParameters: urlParameters):
            if let bodyParameterEncoding = bodyParameterEncoding as? URLEncoding, bodyParameterEncoding.destination != .httpBody {
                print("Only URLEncoding that `bodyEncoding` accepts is URLEncoding.httpBody. Others like `default`, `queryString` or `methodDependent` are prohibited - if you want to use them, add your parameters to `urlParameters` instead.")
            }
            let bodyfulRequest = try request.encoded(parameters: bodyParameters, parameterEncoding: bodyParameterEncoding)
            let urlEncoding = URLEncoding(destination: .queryString)
            return try bodyfulRequest.encoded(parameters: urlParameters, parameterEncoding: urlEncoding)
        }
    }
    
    
    func sha1SaltEncrypt(_ string: String, salt: String) -> String {
        let data = (string + salt).data(using: .utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

}

