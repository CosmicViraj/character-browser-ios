import SwiftUI

struct CharacterListView: View {
    @StateObject private var viewModel = CharacterListViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Characters")
                .searchable(text: $viewModel.searchText, prompt: "Search by name")
        }
        .task {
            await viewModel.onAppear()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading characters...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let characters):
            List {
                ForEach(characters) { character in
                    NavigationLink(value: character.id) {
                        CharacterRow(character: character)
                    }
                    .task {
                        await viewModel.loadNextPageIfNeeded(currentItem: character)
                    }
                }

                if viewModel.isLoadingNextPage {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .refreshable { await viewModel.refresh() }
            .navigationDestination(for: Int.self) { id in
                if let character = characters.first(where: { $0.id == id }) {
                    CharacterDetailView(character: character)
                }
            }

        case .empty:
            ContentUnavailableView.search(text: viewModel.searchText)

        case .failed(let error):
            ContentUnavailableView {
                Label("Couldn't load characters", systemImage: "wifi.exclamationmark")
            } description: {
                Text(error.localizedDescription)
            } actions: {
                Button("Try again") {
                    Task { await viewModel.retry() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    CharacterListView()
}
