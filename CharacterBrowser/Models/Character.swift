import Foundation

struct Character: Identifiable, Decodable, Equatable {
    let id: Int
    let name: String
    let status: Status
    let species: String
    let gender: String
    let imageURL: URL?
    let origin: Location
    let episodeCount: Int

    enum Status: String, Decodable {
        case alive = "Alive"
        case dead = "Dead"
        case unknown

        // The API sends "unknown" in lowercase, but rather than depend on that
        // exact spelling, anything we don't recognise falls back to .unknown
        // instead of failing the whole decode.
        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Status(rawValue: raw) ?? .unknown
        }
    }

    struct Location: Decodable, Equatable {
        let name: String
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, status, species, gender, origin, episode
        case imageURL = "image"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        status = try container.decode(Status.self, forKey: .status)
        species = try container.decode(String.self, forKey: .species)
        gender = try container.decode(String.self, forKey: .gender)
        origin = try container.decode(Location.self, forKey: .origin)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)

        // We only ever display the count, so there's no point holding on to
        // 50 episode URLs per character.
        episodeCount = try container.decode([String].self, forKey: .episode).count
    }
}

#if DEBUG
extension Character {
    static func stub(id: Int = 1,
                     name: String = "Rick Sanchez",
                     status: Status = .alive) -> Character {
        let json = """
        {
          "id": \(id),
          "name": "\(name)",
          "status": "\(status.rawValue)",
          "species": "Human",
          "gender": "Male",
          "image": "https://rickandmortyapi.com/api/character/avatar/\(id).jpeg",
          "origin": { "name": "Earth (C-137)" },
          "episode": ["https://rickandmortyapi.com/api/episode/1"]
        }
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(Character.self, from: json)
    }
}
#endif
