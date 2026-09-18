import Foundation

@MainActor
final class CharacterListViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case loaded([Character])
        case empty
        case failed(APIError)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var isLoadingNextPage = false
    @Published var searchText = "" {
        didSet {
            guard searchText != oldValue else { return }
            scheduleSearch()
        }
    }

    private let service: CharacterServicing
    private var characters: [Character] = []
    private var currentPage = 1
    private var hasNextPage = true
    private var searchTask: Task<Void, Never>?

    /// How long we wait after the last keystroke before hitting the API.
    private let searchDebounce: Duration

    init(service: CharacterServicing = CharacterService(),
         searchDebounce: Duration = .milliseconds(350)) {
        self.service = service
        self.searchDebounce = searchDebounce
    }

    // MARK: - Loading

    func onAppear() async {
        guard case .idle = state else { return }
        await loadFirstPage()
    }

    func retry() async {
        await loadFirstPage()
    }

    func refresh() async {
        await loadFirstPage()
    }

    private func loadFirstPage() async {
        state = .loading
        currentPage = 1
        hasNextPage = true

        do {
            let page = try await service.characters(page: 1, search: searchText)
            characters = page.results
            hasNextPage = page.hasNextPage
            state = characters.isEmpty ? .empty : .loaded(characters)
        } catch {
            let apiError = APIError.map(error)
            // A 404 here means the search simply had no matches, which is an
            // empty state rather than a failure the user needs to act on.
            state = apiError == .notFound ? .empty : .failed(apiError)
        }
    }

    /// Called when the last row appears. Infinite scroll, basically.
    func loadNextPageIfNeeded(currentItem: Character) async {
        guard hasNextPage,
              !isLoadingNextPage,
              currentItem.id == characters.last?.id else { return }

        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        do {
            let next = currentPage + 1
            let page = try await service.characters(page: next, search: searchText)
            currentPage = next
            hasNextPage = page.hasNextPage
            characters.append(contentsOf: page.results)
            state = .loaded(characters)
        } catch {
            // Deliberately quiet: the user already has results on screen, so
            // failing to fetch page N+1 shouldn't blow away what they're reading.
            hasNextPage = false
        }
    }

    // MARK: - Search

    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task { [searchDebounce] in
            try? await Task.sleep(for: searchDebounce)
            guard !Task.isCancelled else { return }
            await loadFirstPage()
        }
    }
}
