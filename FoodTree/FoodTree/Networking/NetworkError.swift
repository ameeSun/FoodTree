import Foundation

enum NetworkError: LocalizedError {
    case unauthorized
    case invalidData
    case decodingError
    case serverError(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You must be logged in to perform this action. Please sign in and try again."
        case .invalidData:
            return "Invalid data provided. Please check your input and try again."
        case .decodingError:
            return "Failed to process server response. Please try again."
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}
