import Foundation

protocol CharacterServicing {
    func characters(page: Int, search: String) async throws -> CharacterPage
}

struct CharacterService: CharacterServicing {
    private let client: HTTPClient
    private let baseURL = URL(string: "https://rickandmortyapi.com/api/character")!

    init(client: HTTPClient = URLSessionHTTPClient()) {
        self.client = client
    }

    func characters(page: Int, search: String = "") async throws -> CharacterPage {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        var items = [URLQueryItem(name: "page", value: String(page))]

        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            items.append(URLQueryItem(name: "name", value: trimmed))
        }
        components.queryItems = items

        guard let url = components.url else { throw APIError.unknown }
        return try await client.get(url)
    }
}
