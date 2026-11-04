# TheMovieDatabase (TMDB) iOS App

An iOS application for browsing popular movies.
Note: This is a pet project created for educational purposes to practice UIKit, Core Data, Unit Testing, and CI/CD.
## Features

- **Popular Movies:** Browse the most popular movies with infinite scrolling (pagination).
- **Search:** Find movies by title with debounced API requests.
- **Movie Details:** View detailed information, posters, and release dates.
- **Favourites:** Save movies to your personal list. The list is persisted offline.
- **Offline Mode:** Core Data caching with a **Cache-First** strategy (instant app launch, background sync).
- **Appearance:** Light and Dark mode support.

## Architecture & Technologies

The project is built following **MVVM** combined with the **Coordinator** pattern for navigation.

- **UI:** UIKit (Programmatic layout, Auto Layout)
- **State Management:** Reactive bindings via closures (`onStateChanged`, `onFavouritesChanged`).
- **Database:** Core Data (with an in-memory store for unit tests).
- **Networking:** Custom `APIClient` using `URLSession`.
- **Image Loading:** Kingfisher.
- **Dependency Injection:** Constructor injection via protocols.
- **Testing:** XCTest (Unit tests for ViewModels and Core Data storage).

### Folder Structure
*   `App/` — App lifecycle and `AppCoordinator`.
*   `Core/` — Constants, Helpers, and global extensions.
*   `Data/` — Repositories, Core Data Stack, Storage, and Networking (API Client).
*   `Features/` — UI screens (Popular, Search, Detail, Favourites, Settings).
*   `Models/` — Domain entities (Movie, PaginatedResponse).

## CI/CD

The project uses **GitHub Actions** for Continuous Integration.
Every push to `main` automatically triggers:
1. Building the project.
2. Running all Unit Tests on an iOS Simulator.

Check the `Actions` tab to see the latest build status.

## How to run

1. Clone the repository:
```bash
   git clone https://github.com/iqqdq/ios_the_movie_database.git
   ```
2. Open TheMovieDatabase.xcodeproj in Xcode (Requires Xcode 15 or later).
3. API Key: You need an API key from https://www.themoviedb.org/documentation/api.
4. Create a Secrets.swift file in TheMovieDatabase/Core/Config/ with the following content:
```
enum Secrets {
    static let apiKey = "YOUR_API_KEY_HERE"
}
```
5. Build and run (Cmd + R).
