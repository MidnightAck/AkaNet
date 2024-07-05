
import Foundation
import CommonCrypto
import HandyJSON
import Reachability


public typealias NetWorkSuccessCallBack = (Dictionary<String,Any>) -> Void

public typealias NetWorkErrorCallBack = ([String: Any]?) -> Void

public typealias NetWorkStreamCallBack = ([String: Any], EventSource?) -> Void

public enum GLAPIRequestType{
    case GLAPIRequestTypeGet
    case GLAPIRequestTypePost
    case GLAPIRequestTypePostFile
    case GLAPIRequestTypeStream
}

// 定义一个结构体来存储重试请求的信息
private struct RetryRequest {
    let request: URLRequest
    let completion: ((Data?, URLResponse?, Error?) -> Void)
}



public let TOKEN_EXPIRED_NOTIFICATION = "token_expired_notification"
public let TOKEN_UPDATE_NOTIFICATION = "token_update_notification"
public let X_IP_Region = "X-IP-Region"
public let X_IP = "X-IP"

public class SessionManager : NSObject{
    
    private static var isRefreshingToken = false
    private static var pendingRequests = [RetryRequest]()
    private static var session = URLSession(configuration: DynamicURLSessionConfiguration.getConfig())

    
    public static func POST(url:String,params:Dictionary<String,Any>,success:@escaping NetWorkSuccessCallBack,
                            failure:@escaping NetWorkErrorCallBack){
        requestWithUrl(URLString: url, parameters: params, requestType: .GLAPIRequestTypePost, success: success, failure: failure)
        
    }
    
    public static func StreamRequest(url:String,params:Dictionary<String,Any>,
                                     success:@escaping NetWorkStreamCallBack,
                                     failure:@escaping NetWorkErrorCallBack) {
        streamRequestWithUrl(URLString: url, parameters: params, requestType: .GLAPIRequestTypePost, success: success, failure: failure)
    }
    
    public static func POSTFile(url:String,params:Dictionary<String,Any>,success:@escaping NetWorkSuccessCallBack,
                                failure:@escaping NetWorkErrorCallBack){
        requestWithUrl(URLString: url, parameters: params, requestType: .GLAPIRequestTypePostFile, success: success, failure: failure)
        
    }
    
    
    public static func GET(url: String,params: Dictionary<String,Any>,success:@escaping NetWorkSuccessCallBack,
                           failure:@escaping NetWorkErrorCallBack) {
        requestWithUrl(URLString: url, parameters: params, requestType: .GLAPIRequestTypeGet, success: success, failure: failure)
        
    }
    
    public static func streamRequestWithUrl(URLString: String,
                                            parameters: Dictionary<String,Any>,
                                            requestType: GLAPIRequestType,
                                            success: @escaping NetWorkStreamCallBack,
                                            failure: @escaping NetWorkErrorCallBack) {
        let urlRequest = genarateRequest(URLString: URLString, parameters: parameters, requestType: .GLAPIRequestTypePost)

        let eventSource = EventSource(url: urlRequest.url!, headers: urlRequest.allHTTPHeaderFields ?? [:] , method: .post, payloadData: urlRequest.httpBody)
        eventSource.connect()
        
        eventSource.onOpen {
            
        }

        eventSource.onComplete {[weak eventSource] statusCode, reconnect, error in
            
            //guard reconnect ?? false else { return }
            
            let base_resp = BaseResp()
            if let error {
                //错误处理
                base_resp.status_msg = error.localizedDescription
                base_resp.status_code = (error as NSError).code
                DispatchQueue.main.async {
                    failure(base_resp.toJSON())
                }
            }
            eventSource?.disconnect()
        }

        eventSource.onMessage { id,event,data in
            
        }
        
        eventSource.addEventListener("UserSendMsgText") {[weak eventSource] id, event, data in
            // 返回 ASR 结果
            let base_resp = BaseResp()
            if let data = data?.data(using: .utf8) {
                guard let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    let errorString = String.init(data: data, encoding: .utf8)
                    base_resp.status_msg = errorString ?? "error"
                    DispatchQueue.main.async {
                        failure(base_resp.toJSON())
                    }
                    return
                }
                DispatchQueue.main.async {
                    success(result ?? [:], eventSource)
                }
            }
        }
        
        eventSource.addEventListener("ReplyMsgText") {[weak eventSource] id, event, data in
            // 返回文本内容
            let base_resp = BaseResp()
            if let data = data?.data(using: .utf8) {
                guard let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    let errorString = String.init(data: data, encoding: .utf8)
                    base_resp.status_msg = errorString ?? "error"
                    DispatchQueue.main.async {
                        failure(base_resp.toJSON())
                    }
                    return
                }
                DispatchQueue.main.async {
                    success(result ?? [:], eventSource)
                }
            }
        }
        
        eventSource.addEventListener("ReplyMsgAudio") {[weak eventSource] id, event, data in
            // 返回音频内容
            let base_resp = BaseResp()
            if let data = data?.data(using: .utf8) {
                guard let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    let errorString = String.init(data: data, encoding: .utf8)
                    base_resp.status_msg = errorString ?? "error"
                    DispatchQueue.main.async {
                        failure(base_resp.toJSON())
                    }
                    return
                }
                DispatchQueue.main.async {
                    success(result ?? [:], eventSource)
                }
            }
        }
        
        eventSource.addEventListener("ReplyMsgTextWithAudio") {[weak eventSource] id, event, data in
            let base_resp = BaseResp()
            if let data = data?.data(using: .utf8) {
                guard let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    let errorString = String.init(data: data, encoding: .utf8)
                    base_resp.status_msg = errorString ?? "error"
                    DispatchQueue.main.async {
                        failure(base_resp.toJSON())
                    }
                    return
                }
                DispatchQueue.main.async {
                    success(result ?? [:], eventSource)
                }
            }
        }
        
        eventSource.addEventListener("VoiceMsg") {[weak eventSource] id, event, data in
            let base_resp = BaseResp()
            if let data = data?.data(using: .utf8) {
                guard let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    let errorString = String.init(data: data, encoding: .utf8)
                    base_resp.status_msg = errorString ?? "error"
                    DispatchQueue.main.async {
                        failure(base_resp.toJSON())
                    }
                    return
                }
                DispatchQueue.main.async {
                    success(result ?? [:], eventSource)
                }
            }
        }
        
        eventSource.addEventListener("BaseResp") {[weak eventSource] id, event, data in
            let base_resp = BaseResp()
            if let data = data?.data(using: .utf8) {
                guard let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    let errorString = String.init(data: data, encoding: .utf8)
                    base_resp.status_msg = errorString ?? "error"
                    DispatchQueue.main.async {
                        failure(base_resp.toJSON())
                    }
                    return
                }
                DispatchQueue.main.async {
                    success(result ?? [:], eventSource)
                }
            }
        }
    }
    
    public static func requestWithUrl(URLString: String,
                                      parameters: Dictionary<String,Any>,
                                      requestType: GLAPIRequestType,
                                      success: @escaping NetWorkSuccessCallBack,
                                      failure: @escaping NetWorkErrorCallBack) {
        let urlRequest = genarateRequest(URLString: URLString, parameters: parameters, requestType: requestType)
        sendRequest(urlRequest) { data, response, error in
            let base_resp = BaseResp()
            if let error {
                //错误处理
                base_resp.status_msg = error.localizedDescription
                base_resp.status_code = (error as NSError).code
                DispatchQueue.main.async {
                    failure(base_resp.toJSON())
                }
                return
            }
            
            if let response = response as? HTTPURLResponse {
                // 这里 header 会随机大小写，所以后续改动要都适配上
                if let trace_id = response.allHeaderFields["trace-id"] as? String{
                    base_resp.trace_id = trace_id
                }
                if let trace_id = response.allHeaderFields["Trace-Id"] as? String{
                    base_resp.trace_id = trace_id
                }
                if let ip_region = response.allHeaderFields["X-Ip-Region"] as? String {
                    let origin_ip_region = AkaNetAdapter.shared.ip_region
                    if origin_ip_region != ip_region {
                        AkaNetAdapter.shared.updateIpRegion(ip_region: ip_region)
                    }
                }
                if response.statusCode != 200 {
                    //错误处理
                    base_resp.status_msg = NSLocalizedString("no_network_error", comment: "")
                    base_resp.status_code = response.statusCode
                    DispatchQueue.main.async {
                        failure(base_resp.toJSON())
                    }
                    return
                }
            }
            
            if let data = data {
                // 系统建议使用的try crash类型，转换JSON失败直接返回nil
                guard var result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    let errorString = String.init(data: data, encoding: .utf8)
                    base_resp.status_msg = errorString ?? "error"
                    return
                }
                if let response = response as? HTTPURLResponse {
                    // 这里 header 会随机大小写，所以后续改动要都适配上
                    if let trace_id = response.allHeaderFields["trace-id"] as? String{
                        result["trace_id"] = trace_id
                    }
                    if let trace_id = response.allHeaderFields["Trace-Id"] as? String{
                        result["trace_id"] = trace_id
                    }
                    /*
                    if let ip_region = response.allHeaderFields["X-Ip-Region"] as? String {
                        let origin_ip_region = AkaNetAdapter.shared.ip_region
                    }
                    if let ip_region = response.allHeaderFields["x-ip-region"] as? String {
                        let origin_ip_region = AkaNetAdapter.shared.ip_region
                    }
                     */
                }
                DispatchQueue.main.async {
                    success(result)
                }
            }else {
                DispatchQueue.main.async {
                    failure([:]) //请求失败,result传nil,传入error
                }
            }
        }
    }
    
    public static func updateSession() {
        session.invalidateAndCancel()
        DynamicURLSessionConfiguration.switchConfig()
        session = URLSession(configuration: DynamicURLSessionConfiguration.getConfig())
    }
    
    private static func genarateRequest(URLString: String,
                                        parameters: [String: Any],
                                        requestType: GLAPIRequestType) -> URLRequest{
        
        var request = URLRequest(url: URL(string: URLString)!)
        request.timeoutInterval = TimeInterval(AkaNetAdapter.shared.getTimeOut(path: URLString) / 1000)
        request.httpMethod = (requestType == .GLAPIRequestTypePost) ? "POST" :"GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do{
            if(requestType == .GLAPIRequestTypePost){
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                let paramsString = AkaNetAdapter.shared.commonParams().map{ (k:String,v:Any) -> String in
                    let string = String(format:"%@=%@",k,String(describing: v))
                    return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
                }
                request.url = URL(string: URLString + "?" + paramsString.joined(separator:"&"))
            }else if(requestType == .GLAPIRequestTypeGet){
                let paramsString = parameters.map{ (k:String,v:Any) -> String in
                    return String(format:"%@=%@",k,String(describing: v))
                }
                request.url = URL(string: URLString + "?" + (paramsString.joined(separator:"&").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""))
            }else{
                let boundary = getRandomBoundary()
                let body  = NSMutableArray()
                var fileTmpStr = ""
                request.httpMethod = "POST"
                request.setValue("multipart/form-data; boundary=----\(boundary)", forHTTPHeaderField: "Content-Type")
                //拆分字典,parameter是其中一项，将key与value变成字符串
                for parameter in parameters {
                    // 将boundary和parameter组装在一起
                    if(parameter.0 == "base_image"){
                        continue
                    }
                    fileTmpStr = "------\(boundary)\r\nContent-Disposition: form-data; name=\"\(parameter.0)\"\r\n\r\n\(parameter.1)\r\n"
                    body.add(fileTmpStr)
                }
                // 上传文件的文件名，按照需求起名字就好
                //                let filename = String(MIXUser.shared.user_id) + ":" + String(Int(Date().timeIntervalSince1970))
                let filename = String(Int(Date().timeIntervalSince1970))
                // 将文件名和boundary组装在一起
                fileTmpStr = "------\(boundary)\r\nContent-Disposition: form-data; name=\"base_image\"; filename=\"\(filename)\"\r\n"
                body.add(fileTmpStr)
                // 文件类型是图片，png、jpeg随意
                fileTmpStr = "Content-Type: image/png\r\n\r\n"
                body.add(fileTmpStr)
                // 将body里的内容转成字符串
                let parameterStr = body.componentsJoined(by: "")
                // UTF8转码，防止汉字符号引起的非法网址
                var parameterData = parameterStr.data(using: String.Encoding.utf8)!
                parameterData.append(parameters["base_image"] as! Data)
                // 将boundary结束部分追加进parameterData
                parameterData.append("\r\n------\(boundary)--".data(using: String.Encoding.utf8)!)
                // 设置请求体
                request.httpBody = parameterData
                
            }
        }catch{
            //TODO: 错误处理
        }
#if DEBUG
        if (request.url?.path) != nil{
            //            DebugRequestManager.manager.addAddress(address: path)
            //            if let lane = DebugRequestManager.manager.getLane(address: path){
            //                request.setValue(lane, forHTTPHeaderField: "Lane")
            //            }
        }
#endif
        var header = headerCommonParams()
        let keys = requestType == .GLAPIRequestTypeGet ? Array(parameters.keys) : Array(AkaNetAdapter.shared.commonParams().keys)
        let sortedKeys = keys.sorted()
        let paramStringList = sortedKeys.map { key in
            let string = String(format:"%@=%@",key,String(describing: requestType == .GLAPIRequestTypeGet ? parameters[key] ?? "" : AkaNetAdapter.shared.commonParams()[key] ?? ""))
            return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
        }
        var signString:String = paramStringList.joined(separator: "&")
        if requestType == .GLAPIRequestTypePost{
            do{
                let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
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
        header["x-timestamp"] = timeStamp
        header["x-sign"] = sign
        if let ip_region = AkaNetAdapter.shared.ip_region {
            header["ip_region"] = ip_region
        }
        if let sys_region = Locale.current.regionCode {
            header["sys_region"] = sys_region
        }
        request.allHTTPHeaderFields = header
        return request
        
    }
    
    private static func sendRequest(_ request: URLRequest, retryCount: Int = 3, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let authenticatedRequest = request
        session.dataTask(with: authenticatedRequest) { (data, response, error) in
            // 埋点
            let reachability = try! Reachability()
            trackRequestResult(data: data, response: response as? HTTPURLResponse, error: error)
            // 错误处理,这种一般是端上请求没有发出去等,没有把请求发出去,先重试,重试还没好直接跑出错误
            if let error = error as NSError?, error.domain == NSURLErrorDomain {
                if reachability.currentReachabilityStatus() == .NotReachable {
                    completion(data, response, error)
                    return
                }
                if error.code == NSURLErrorDNSLookupFailed {
                    updateSession()
                }
                if error.code != -1005, error.code != -1001, retryCount > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Delay for 1 second and then retry
                        sendRequest(request, retryCount: retryCount - 1, completion: completion)
                    }
                }
            } else {
                completion(data, response, error)
            }
        }.resume()
    }
    
    private static func handlePendingRequests() {
        let requests = pendingRequests
        pendingRequests.removeAll()
        
        for retryRequest in requests {
            var authenticatedRequest = retryRequest.request
            let header = headerCommonParams()
            authenticatedRequest.allHTTPHeaderFields = header
            session.dataTask(with: authenticatedRequest, completionHandler: retryRequest.completion).resume()
        }
    }
    
    private static func dropPendingRequests(data: Data?, response: URLResponse?, error: Error?) {
        for pendingRequest in pendingRequests {
            pendingRequest.completion(data,response,error)
        }
        pendingRequests.removeAll()
    }
    
    private static func trackRequestResult(data: Data?, response: HTTPURLResponse?, error: Error?) {
        var status_code = response?.statusCode
        var path = response?.url?.path
        if let data, let des = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
            let commonResponse = CommonResponse.deserialize(from: des)
            status_code = commonResponse?.base_resp.status_code
        }
//        Track.shared.ec(withEventId: "request_result", ext: ["status_code": status_code ?? -1,
//                                                             "path": path ?? "",
//                                                             "error_code": (error as? NSError)?.code ?? 0,
//                                                             "error_msg": (error as? NSError)?.localizedDescription ?? ""])
    }
}

class DynamicURLSessionConfiguration: URLSessionConfiguration {
    
    static let ips: [String] = AkaNetAdapter.shared.dynamicIps
    
    static var currentPickIdx: Int = 0
    static var runOut: Bool = false

    public static func switchConfig() {
        if currentPickIdx == ips.count - 1 {
            runOut = true
            return
        }
        currentPickIdx = (currentPickIdx + 1) % (ips.count + 1)
    }
    
    public static func getConfig() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
//        config.waitsForConnectivity = true
//        if currentPickIdx != 0, !runOut, let ip = ips[safeIndex: currentPickIdx] {
//            config.connectionProxyDictionary = [
//                kCFNetworkProxiesHTTPEnable as AnyHashable: true,
//                kCFNetworkProxiesHTTPProxy as AnyHashable: ip,
//                kCFNetworkProxiesHTTPPort as AnyHashable: 443,
//            ]
//        }
        return config

    }
}

func headerCommonParams() -> [String: String] {
    return AkaNetAdapter.shared.headerParams()
}

func sha1SaltEncrypt(_ string: String, salt: String) -> String {
    let data = (string + salt).data(using: .utf8)!
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
    data.withUnsafeBytes {
        _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
    }
    return digest.map { String(format: "%02x", $0) }.joined()
}

// MARK: - 获取boundary
private func getRandomBoundary() -> String {
    // 这个Boundary是随机数
    return String(format: "WebKitFormBoundary%08x%08x", arc4random(), arc4random())
}

extension NSMutableData{
    func appendString(_ string: String) {
          let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
          append(data!)
      }
}
