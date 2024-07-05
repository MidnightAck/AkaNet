//
//  AkaNetworkService.swift
//  AkaNet
//
//  Created by fushiguro on 2024/7/5.
//


import Foundation
import HandyJSON
import Combine

public class AkaNetworkService : NSObject{
    public static func GET(address:String,params:Dictionary<String,Any>?, priority: RequestPriority = .low, block:@escaping GLCompleteBlock){
        NetworkService.shared.GET(address: address, params: params, priority: priority, domainType: .normal, block: block)
    }
    
    public static func POST(address:String,params:Dictionary<String,Any>, priority: RequestPriority = .low, isStreaming:Bool = false,block:@escaping GLCompleteBlock){
        NetworkService.shared.POST(address: address, params: params, priority: priority, domainType: .normal, block: block)
    }
    
    public static func StreamRequest(address:String,params:Dictionary<String,Any>,block:@escaping GLCStreamCompleteBlock) {
        StreamManager.StreamRequest(address: address, params: params, block: block)
    }
    
    public static func getBaseResp(res:Dictionary<String,Any>) -> BaseResp{
        return BaseResp.deserialize(from: (res["base_resp"] as? Dictionary)) ?? BaseResp()
    }
}


