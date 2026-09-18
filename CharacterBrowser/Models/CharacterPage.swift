import Foundation

/// One page of results from the `/character` endpoint.
struct CharacterPage: Decodable {
    let info: Info
    let results: [Character]

    struct Info: Decodable {
        let count: Int
        let pages: Int
        let next: URL?
    }

    var hasNextPage: Bool { info.next != nil }
}
