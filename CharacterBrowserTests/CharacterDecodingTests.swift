import XCTest
@testable import CharacterBrowser

final class CharacterDecodingTests: XCTestCase {

    func test_decodesACharacterFromTheAPIShape() throws {
        let json = """
        {
          "id": 1,
          "name": "Rick Sanchez",
          "status": "Alive",
          "species": "Human",
          "gender": "Male",
          "origin": { "name": "Earth (C-137)" },
          "image": "https://rickandmortyapi.com/api/character/avatar/1.jpeg",
          "episode": [
            "https://rickandmortyapi.com/api/episode/1",
            "https://rickandmortyapi.com/api/episode/2"
          ]
        }
        """.data(using: .utf8)!

        let character = try JSONDecoder().decode(Character.self, from: json)

        XCTAssertEqual(character.id, 1)
        XCTAssertEqual(character.name, "Rick Sanchez")
        XCTAssertEqual(character.status, .alive)
        XCTAssertEqual(character.origin.name, "Earth (C-137)")
        XCTAssertEqual(character.episodeCount, 2)
    }

    func test_anUnrecognisedStatusFallsBackToUnknown() throws {
        let json = """
        {
          "id": 9, "name": "Test", "status": "Schrodinger",
          "species": "Alien", "gender": "unknown",
          "origin": { "name": "unknown" },
          "image": "https://example.com/9.jpeg",
          "episode": []
        }
        """.data(using: .utf8)!

        let character = try JSONDecoder().decode(Character.self, from: json)

        XCTAssertEqual(character.status, .unknown)
    }

    func test_missingImageDoesNotBreakDecoding() throws {
        let json = """
        {
          "id": 10, "name": "No Photo", "status": "Dead",
          "species": "Alien", "gender": "Female",
          "origin": { "name": "Abadango" },
          "episode": []
        }
        """.data(using: .utf8)!

        let character = try JSONDecoder().decode(Character.self, from: json)

        XCTAssertNil(character.imageURL)
        XCTAssertEqual(character.status, .dead)
    }
}
