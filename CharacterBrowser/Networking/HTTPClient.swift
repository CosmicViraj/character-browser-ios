import Foundation

/// Thin wrapper around URLSession so the rest of the app never touches it directly.
/// Keeping this behind a protocol is what lets the tests run without a network.
protocol HTTPClient {
    func get<T: Decodable>(_ url: URL) async throws -> T
}

struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        switch http.statusCode {
        case 200..<300:
            break
        case 404:
            // The API uses 404 for "no results" on a search, not just bad URLs.
            throw APIError.notFound
        default:
            throw APIError.server(statusCode: http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
