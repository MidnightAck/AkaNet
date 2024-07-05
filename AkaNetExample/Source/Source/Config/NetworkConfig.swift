//
//  NetworkConfig.swift
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

public enum DomianType: Int {
    case normal = 0
    case streaming = 1
}

struct AkaBasicMoyaModel {
    var url: String
    var method: AkaNet.Method
    var params: [String: Any]
}

// MARK: - GET POST
public enum AkaBasicMoyaAPI {
    case get(url: String, params: [String: Any], domainType: DomianType)
    case post(url: String, params: [String: Any], domainType: DomianType)
}

extension AkaBasicMoyaAPI: TargetType {
    public var baseURL: URL {
        switch self {
        case .get(_, _, let domainType):
            var domain = AkaNetAdapter.shared.domain()
            if domainType == .streaming {
                domain = AkaNetAdapter.shared.streamingDomain()
            }
            return URL(string: domain)!
        case .post(_, _, let domainType):
            var domain = AkaNetAdapter.shared.domain()
            if domainType == .streaming {
                domain = AkaNetAdapter.shared.streamingDomain()
            }
            return URL(string: domain)!
        }
    }
    
    public var path: String {
        switch self {
        case .get(let url, params: _, _):
            return url
        case .post(let url, params: _, _):
            return url
        }
    }
    
    public var method: AkaNet.Method {
        switch self {
        case .get(_, _, _):
            return .get
        case .post(_, _, _):
            return .post
        }
    }
    
    public var sampleData: Data {
        return Data()
    }
    
    public var bodyParams: [String: Any] {
        switch self {
        case .get(_, let params, _), .post(_, let params, _):
            return params
        }
    }
    
    public var task: MoyaTask {
        switch self {
        case .get(_, let params, _), .post(_, let params, _):
            return .requestCompositeParameters(bodyParameters: params, bodyEncoding: JSONEncoding.default, urlParameters: moyaCommonParams())
        }
    }
    
    public var validationType: ValidationType {
        return .none
    }
    
    public var headers: [String : String]? {
        return AkaNetAdapter.shared.headerParams()
    }
    
    private func moyaCommonParams() -> [String: Any] {
        var urlParams: [String: Any] = [:]
        urlParams.merge(AkaNetAdapter.shared.commonParams()) { $1 }
        
        return urlParams
    }
}

// MARK: - Upload
public enum AkaBasicMoyaUploadAPI {
    case upload(url: URL, data: Data)
}

extension AkaBasicMoyaUploadAPI: TargetType {
    public var bodyParams: [String : Any] {
        return [:]
    }
    
    public var baseURL: URL {
        switch self {
        case .upload(let url, _):
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.query = nil
            return URL(string: components?.string ?? "")!
        }
    }
    
    public var path: String {
        switch self {
        case .upload(let url, _):
            return url.path
        }
    }
    
    public var method: AkaNet.Method {
        return .put
    }
    
    public var sampleData: Data {
        return Data()
    }
    
    public var task: MoyaTask {
        switch self {
        case .upload(let url, let data):
            var formData: [MultipartFormData] = []
            let formDataItem = MultipartFormData(provider: .data(data), name: "file", fileName: url.lastPathComponent, mimeType: "image/jpeg")
            formData.append(formDataItem)
            
            return .uploadCompositeMultipart(formData, urlParameters: moyaCommonParams())
        }
    }
    
    public var validationType: ValidationType {
        return .none
    }
    
    public var headers: [String : String]? {
        var headerParams = AkaNetAdapter.shared.headerParams()
        switch self {
        case .upload(_, _):
            headerParams["Content-Disposition"] = "inline"
        }
        return headerParams
    }
    
    private func moyaCommonParams() -> [String: Any] {
        var urlParams: [String: Any] = [:]
        urlParams.merge(AkaNetAdapter.shared.commonParams()) { $1 }
        
        return urlParams
    }

}
