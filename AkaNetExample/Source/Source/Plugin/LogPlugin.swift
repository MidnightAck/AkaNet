//
//  LogPlugin.swift
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

class LogPlugin: PluginType {
    private var successCount: [String: Int] = [:]
    private var failureCount: [String: Int] = [:]
    private var totalTime: [String: Double] = [:]
    private var startTime: Date?
    
    private var pathsToDetect: [String] = AkaNetLogAdapter.shared.logPath

    func willSend(_ request: RequestType, target: TargetType) {
        startTime = Date()
    }

    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        guard let startTime = startTime else { return }

        let endTime = Date()
        let elapsedTime = endTime.timeIntervalSince(startTime)

        guard shouldDetect(for: target) else {
            return
        }

        var resJson: Any?
        switch result {
        case .success(let res):
            do {
                resJson = try JSONSerialization.jsonObject(with: res.data, options: [])
            } catch {}
        case .failure(let error):
            do {
                if let data = error.response?.data {
                    resJson = try JSONSerialization.jsonObject(with: data, options: [])
                }
            } catch {}
            break
        }
        AkaNetLogAdapter.shared.log(custom: ["path" : target.path,
                                            "body": target.bodyParams,
                                            "duration": elapsedTime,
                                            "response": resJson ?? ""])

    }

    private func shouldDetect(for target: TargetType) -> Bool {
        return pathsToDetect.contains(target.path)
    }
}
