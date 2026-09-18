# Walkthrough

Notes on how the app is put together and why, written so I can talk through
any file in a review.

## The data flow, end to end

1. `CharacterListView` appears and calls `viewModel.onAppear()`.
2. The view model sets `state = .loading`, then awaits
   `CharacterService.characters(page:search:)`.
3. `CharacterService` builds the URL (`?page=1&name=rick`) and hands it to
   `URLSessionHTTPClient`.
4. The client does `await session.data(from:)`, checks the status code, and
   decodes into `CharacterPage`.
5. The view model stores the results and sets `state = .loaded([...])`.
6. Because `state` is `@Published` and the view holds the view model as a
   `@StateObject`, SwiftUI re-renders the list.

Anything that throws along the way gets funnelled through `APIError.map(_:)`
so the UI only ever deals with one error type.

## Why the protocols exist

`HTTPClient` and `CharacterServicing` are both protocols with one concrete
implementation each. That looks like over-engineering until you look at the
tests: `MockCharacterService` conforms to `CharacterServicing`, so every view
model test runs in milliseconds with no network and no flakiness. Dependencies
are injected through initialisers with production defaults, so app code stays
`CharacterListViewModel()` while tests pass a mock in.

## Concurrency

- The view model is marked `@MainActor`, so every published property is
  mutated on the main thread. No `DispatchQueue.main.async` anywhere.
- Networking is `async`/`await` on `URLSession`, which hops off the main
  actor automatically.
- Search is debounced by cancelling the previous `Task` and sleeping
  350 ms before firing. Typing "rick" produces one request, not four.
  The debounce interval is injectable so tests can set it to zero.

## Pagination

`loadNextPageIfNeeded(currentItem:)` is attached to each row's `.task`
modifier. It returns immediately unless three things hold: there is a next
page, we aren't already fetching one, and the row that appeared is the last
one in the array. That's the cheapest way to get infinite scroll without a
`GeometryReader` or scroll-offset maths.

## Likely questions and the answers

**Why `@StateObject` and not `@ObservedObject`?**
The view creates the view model, so it owns it. `@StateObject` keeps the same
instance alive across re-renders; `@ObservedObject` would recreate it and
re-fetch every time the parent redraws.

**Why `private(set)` on `state`?**
The view should read state, never set it. All transitions go through view
model methods, so there's one place to look when the UI misbehaves.

**How would you cache images?**
`AsyncImage` only caches in `URLCache` at the session level. For real use I'd
either configure a shared `URLCache` with a disk capacity, or drop in a small
actor-based cache keyed by URL.

**What would you test next?**
`URLSessionHTTPClient` against a `URLProtocol` stub, so status-code mapping
and decoding failures are covered at that layer too, plus a couple of snapshot
tests on `CharacterRow`.

**Where does this break at scale?**
Everything is kept in one array in memory. Past a few thousand rows you'd want
a paged store backed by SwiftData or Core Data, and you'd want to diff pages
rather than append blindly, since the API can return duplicates near page
boundaries.
