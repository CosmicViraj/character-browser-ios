import Foundation

enum APIError: LocalizedError, Equatable {
    case offline
    case notFound
    case server(statusCode: Int)
    case decoding
    case unknown

    var errorDescription: String? {
        switch self {
        case .offline:
            return "You appear to be offline. Check your connection and try again."
        case .notFound:
            return "No characters matched that search."
        case .server(let code):
            return "The server returned an error (\(code)). Please try again."
        case .decoding:
            return "We couldn't read the response from the server."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }

    /// Maps whatever URLSession / JSONDecoder threw into something we can show a user.
    static func map(_ error: Error) -> APIError {
        if let apiError = error as? APIError { return apiError }
        if error is DecodingError { return .decoding }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut:
                return .offline
            default:
                return .unknown
            }
        }
        return .unknown
    }
}
