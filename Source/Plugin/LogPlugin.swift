
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
