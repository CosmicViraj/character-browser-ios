import SwiftUI

struct CharacterDetailView: View {
    let character: Character

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AsyncImage(url: character.imageURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Color(.secondarySystemBackground)
                        .frame(height: 280)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)

                VStack(spacing: 8) {
                    Text(character.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    StatusBadge(status: character.status)
                }

                VStack(spacing: 0) {
                    DetailRow(title: "Species", value: character.species)
                    Divider()
                    DetailRow(title: "Gender", value: character.gender)
                    Divider()
                    DetailRow(title: "Origin", value: character.origin.name)
                    Divider()
                    DetailRow(title: "Episodes", value: "\(character.episodeCount)")
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        CharacterDetailView(character: .stub())
    }
}
