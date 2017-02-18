import Foundation

public enum PathKitError: Swift.Error {
    case InvalidString
    case custom(type: String, message: String)
}
