
import Foundation

public protocol NetworkAuthProtocol {
    var auth_headers: [String: String] { get }
    var common_params: [String: Any] { get }
}
