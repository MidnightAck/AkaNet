//
//  NetworkTypeManager.swift
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
import Reachability
import CoreTelephony

public typealias StreamCompleteBlock = (_ data:Dictionary<String,Any>, EventSource?) -> Void
public typealias CompleteBlock = (_ data:Dictionary<String,Any>) -> Void

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
