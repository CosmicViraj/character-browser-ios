import Foundation
@testable import CharacterBrowser

/// Stands in for the real service so tests never touch the network.
final class MockCharacterService: CharacterServicing {

    enum Response {
        case success(CharacterPage)
        case failure(Error)
    }

    /// Keyed by page number so we can script pagination behaviour.
    var responses: [Int: Response] = [:]
    private(set) var requestedPages: [Int] = []
    private(set) var requestedSearches: [String] = []

    func characters(page: Int, search: String) async throws -> CharacterPage {
        requestedPages.append(page)
        requestedSearches.append(search)

        switch responses[page] {
        case .success(let page):
            return page
        case .failure(let error):
            throw error
        case nil:
            throw APIError.unknown
        }
    }
}

extension CharacterPage {
    static func make(_ characters: [Character], hasNext: Bool = false) -> CharacterPage {
        let json = """
        {
          "info": {
            "count": \(characters.count),
            "pages": \(hasNext ? 2 : 1),
            "next": \(hasNext ? "\"https://rickandmortyapi.com/api/character?page=2\"" : "null")
          },
          "results": []
        }
        """.data(using: .utf8)!

        let decoded = try! JSONDecoder().decode(CharacterPage.self, from: json)
        return CharacterPage(info: decoded.info, results: characters)
    }
}
