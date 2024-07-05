import Foundation
import Reachability
import CoreTelephony
import HandyJSON

public typealias GLCStreamCompleteBlock = (_ data:Dictionary<String,Any>, EventSource?) -> Void
public typealias GLCompleteBlock = (_ data:Dictionary<String,Any>) -> Void

open class CommonResponse: HandyJSON{
    
    /// 基础返回对象
    public var base_resp: BaseResp = BaseResp()
    public var trace_id:String?
    required public init(){}
}

public class BaseResp: HandyJSON{
    
    /// 返回状态码 默认： -1
    public var status_code:Int = -1
    
    /// 默认 ：解析错误
    public var status_msg : String = "Error, please try again"
    
    public var trace_id: String?
    public var trace_info_str: String?

    required public init() {}
}

public class NetworkTypeManager: NSObject {
    
    public class func getNetworkType()->String {
        do{
            let reachability: Reachability = try Reachability()
            try reachability.startNotifier()
            let status = reachability.currentReachabilityStatus()
            if status == .ReachableViaWWAN {
                let networkInfo = CTTelephonyNetworkInfo()
                
                if let currentRadioAccessTechnology = networkInfo.currentRadioAccessTechnology {
                    if #available(iOS 14.1, *) {
                        switch currentRadioAccessTechnology {
                        case CTRadioAccessTechnologyNR, CTRadioAccessTechnologyNRNSA:
                            return "5G"
                        case CTRadioAccessTechnologyLTE:
                            return "4G"
                        case CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyCDMAEVDORev0, CTRadioAccessTechnologyCDMAEVDORevA, CTRadioAccessTechnologyCDMAEVDORevB:
                            return "3G"
                        case CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyGPRS:
                            return "2G"
                        default:
                            return "unavailable"
                        }
                    } else {
                        return "unavailable"
                    }
                } else {
                    return "unavailable"
                }
            }else if status == .ReachableViaWiFi {
                return "WIFI"
            }else if status == .NotReachable {
                return "unavailable"
            }else{
                return "unavailable"
            }
        }catch{
            return "unavailable"
        }
        
        return "unavailable"
    }
    
}
