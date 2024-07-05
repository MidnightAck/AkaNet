//
//  AkaNetworkService.swift
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
import Combine

public class AkaNetworkService : NSObject{
    public static func GET(address:String,params:Dictionary<String,Any>?, priority: RequestPriority = .low, block:@escaping CompleteBlock){
        NetworkService.shared.GET(address: address, params: params, priority: priority, domainType: .normal, block: block)
    }
    
    public static func POST(address:String,params:Dictionary<String,Any>, priority: RequestPriority = .low, isStreaming:Bool = false,block:@escaping CompleteBlock){
        NetworkService.shared.POST(address: address, params: params, priority: priority, domainType: .normal, block: block)
    }
    
    public static func StreamRequest(address:String,params:Dictionary<String,Any>,block:@escaping StreamCompleteBlock) {
        StreamManager.StreamRequest(address: address, params: params, block: block)
    }
    
}


