
import Foundation
import HandyJSON

public class StreamManager: NSObject {
    public static func StreamRequest(address:String,params:Dictionary<String,Any>, block:@escaping GLCStreamCompleteBlock) {
        let url = AkaNetAdapter.shared.streamingDomain() + address
        SessionManager.StreamRequest(url: url, params: params, success: block) { error in
            let baseResp = BaseResp.deserialize(from: error)
            block(["base_resp":["status_code": baseResp?.status_code ?? -1,
                                "status_msg": baseResp?.status_msg ?? NSLocalizedString("no_network_error", comment: "")] as [String : Any]] , nil)
        }
    }
}
