# CharacterBrowser

A small SwiftUI app that fetches characters from the public
[Rick and Morty API](https://rickandmortyapi.com) and shows them in a list,
with search, infinite scroll and a detail screen.

Built for the iOS practical assignment.

## Requirements

- Xcode 16 or later
- iOS 17.0+ simulator or device

No third-party dependencies, no API key.

## Running it

```bash
git clone <your-repo-url>
cd CharacterBrowser
open CharacterBrowser.xcodeproj
```

Pick any iOS 17+ simulator and hit Run. Tests run with Cmd+U, or:

```bash
xcodebuild test \
  -project CharacterBrowser.xcodeproj \
  -scheme CharacterBrowser \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## What it does

- Lists characters with avatar, name, species and a colour-coded status badge
- Search by name, debounced so it doesn't fire a request per keystroke
- Infinite scroll — the next page loads when the last row appears
- Pull to refresh
- Tap through to a detail screen (origin, gender, episode count)
- Proper loading, empty and error states, with a retry button

## Structure

```
CharacterBrowser/
├── Models/          Character, CharacterPage — Codable, no logic
├── Networking/      HTTPClient (URLSession wrapper), CharacterService, APIError
├── ViewModels/      CharacterListViewModel — all the state lives here
└── Views/           CharacterListView, CharacterRow, CharacterDetailView, StatusBadge
CharacterBrowserTests/
├── CharacterListViewModelTests.swift
├── CharacterDecodingTests.swift
└── Mocks/MockCharacterService.swift
```

MVVM, with the network layer behind two protocols (`HTTPClient` and
`CharacterServicing`). That's the main reason the view model is testable
without a network connection — the tests inject `MockCharacterService`.

## Notes on a few decisions

**Why a `Status` enum with a custom decoder.** The API sends `"Alive"`,
`"Dead"` or `"unknown"`. An enum makes the view code exhaustive, and the custom
`init(from:)` means an unexpected value degrades to `.unknown` instead of
failing the entire response.

**Why `episodeCount` instead of the episode array.** Each character ships up to
50 episode URLs and the UI only ever shows the number, so the model collapses
them at decode time.

**Why a single `State` enum instead of separate `isLoading` / `error` /
`items` properties.** Those combinations can contradict each other
(`isLoading == true` alongside a populated error). One enum makes the
impossible states unrepresentable and the view is a straight `switch`.

**Why pagination failures are silent.** If page 3 fails while the user is
reading pages 1 and 2, replacing the screen with an error would be hostile.
It stops paginating and leaves what's on screen alone.

**404 is an empty state, not an error.** The API returns 404 when a name search
matches nothing, so the view model maps that case to `.empty`.

## Known limitations

Given the scope, I left out: image caching beyond what `AsyncImage` does in
memory, offline persistence, and localisation of the user-facing strings.
Those would be the first three things to add.
