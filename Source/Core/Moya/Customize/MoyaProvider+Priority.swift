
import Foundation

public enum RequestPriority {
    case high
    case low
}

public extension MoyaProvider {
    func addRequestToQueue(_ request: @escaping () -> Void, priority: RequestPriority) {
        MoyaService.synchronizationQueue.async {
            MoyaService.waitingRequestsQueue.append((request, priority))
            MoyaService.waitingRequestsQueue.sort(by: { $0.1 == .high && $1.1 != .high })
        }
    }

}
