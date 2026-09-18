import XCTest
@testable import CharacterBrowser

@MainActor
final class CharacterListViewModelTests: XCTestCase {

    private var service: MockCharacterService!

    override func setUp() {
        super.setUp()
        service = MockCharacterService()
    }

    private func makeSUT() -> CharacterListViewModel {
        // Zero debounce keeps the search tests fast and deterministic.
        CharacterListViewModel(service: service, searchDebounce: .zero)
    }

    func test_onAppear_loadsFirstPage() async {
        let characters = [Character.stub(id: 1), Character.stub(id: 2, name: "Morty")]
        service.responses[1] = .success(.make(characters))

        let sut = makeSUT()
        await sut.onAppear()

        XCTAssertEqual(sut.state, .loaded(characters))
        XCTAssertEqual(service.requestedPages, [1])
    }

    func test_onAppear_withNoResults_showsEmptyState() async {
        service.responses[1] = .success(.make([]))

        let sut = makeSUT()
        await sut.onAppear()

        XCTAssertEqual(sut.state, .empty)
    }

    func test_onAppear_whenServerFails_showsError() async {
        service.responses[1] = .failure(APIError.server(statusCode: 500))

        let sut = makeSUT()
        await sut.onAppear()

        XCTAssertEqual(sut.state, .failed(.server(statusCode: 500)))
    }

    func test_notFound_isTreatedAsEmptyNotAsAnError() async {
        // The API returns 404 when a search matches nothing, which is not
        // something the user needs a "try again" button for.
        service.responses[1] = .failure(APIError.notFound)

        let sut = makeSUT()
        await sut.onAppear()

        XCTAssertEqual(sut.state, .empty)
    }

    func test_loadNextPage_appendsToExistingResults() async {
        let first = [Character.stub(id: 1)]
        let second = [Character.stub(id: 2, name: "Summer")]
        service.responses[1] = .success(.make(first, hasNext: true))
        service.responses[2] = .success(.make(second))

        let sut = makeSUT()
        await sut.onAppear()
        await sut.loadNextPageIfNeeded(currentItem: first[0])

        XCTAssertEqual(sut.state, .loaded(first + second))
        XCTAssertEqual(service.requestedPages, [1, 2])
    }

    func test_loadNextPage_isIgnoredWhenNotAtTheLastRow() async {
        let characters = [Character.stub(id: 1), Character.stub(id: 2)]
        service.responses[1] = .success(.make(characters, hasNext: true))

        let sut = makeSUT()
        await sut.onAppear()
        await sut.loadNextPageIfNeeded(currentItem: characters[0])

        XCTAssertEqual(service.requestedPages, [1])
    }

    func test_loadNextPage_isIgnoredOnTheLastPage() async {
        let characters = [Character.stub(id: 1)]
        service.responses[1] = .success(.make(characters, hasNext: false))

        let sut = makeSUT()
        await sut.onAppear()
        await sut.loadNextPageIfNeeded(currentItem: characters[0])

        XCTAssertEqual(service.requestedPages, [1])
    }

    func test_failingNextPage_keepsTheResultsAlreadyOnScreen() async {
        let first = [Character.stub(id: 1)]
        service.responses[1] = .success(.make(first, hasNext: true))
        service.responses[2] = .failure(APIError.offline)

        let sut = makeSUT()
        await sut.onAppear()
        await sut.loadNextPageIfNeeded(currentItem: first[0])

        XCTAssertEqual(sut.state, .loaded(first))
    }

    func test_search_refetchesFromPageOneWithTheQuery() async {
        service.responses[1] = .success(.make([Character.stub(id: 1)]))

        let sut = makeSUT()
        await sut.onAppear()

        sut.searchText = "rick"
        // Give the debounced task a moment to fire.
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(service.requestedPages, [1, 1])
        XCTAssertEqual(service.requestedSearches.last, "rick")
    }
}
