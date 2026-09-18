import SwiftUI

struct CharacterRow: View {
    let character: Character

    var body: some View {
        HStack(spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(character.species)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                StatusBadge(status: character.status)
            }
        }
        .padding(.vertical, 4)
    }

    private var avatar: some View {
        AsyncImage(url: character.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                Image(systemName: "person.fill")
                    .foregroundStyle(.secondary)
            default:
                Color(.secondarySystemBackground)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview {
    List {
        CharacterRow(character: .stub())
        CharacterRow(character: .stub(id: 2, name: "Birdperson", status: .dead))
    }
    .listStyle(.plain)
}
