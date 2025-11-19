import Foundation

enum NetworkError: Error {
    case unauthorized
    case invalidData
    case decodingError
    case serverError(String)
    case unknown
}
