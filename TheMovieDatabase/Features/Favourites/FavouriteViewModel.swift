//
//  FavouriteViewModel.swift
//  TheMovieDatabase
//
//  Created by Artur on 23.10.2026.
//

import Foundation

final class FavouritesViewModel {
    
    // MARK: - Dependencies

    private let repository: MovieRepositoryProtocol

    // MARK: - Observers

    private var favouriteObserver: NSObjectProtocol?
    
    // MARK: - Output

    private(set) var movies: [Movie] = []
    
    private(set) var state: FavouritesState = .idle {
        didSet { onStateChanged?(state) }
    }

    var onStateChanged: ((FavouritesState) -> Void)?
    
    // MARK: - Init

    init(repository: MovieRepositoryProtocol = MovieRepository()) {
        self.repository = repository

        // Подписываемся на изменения избранного
        favouriteObserver = NotificationCenter.default.addObserver(
            forName: .favouritesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.fetchFavourites()
        }
    }

    deinit {
        if let observer = favouriteObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public

    func fetchFavourites() {
        if movies.isEmpty {
            state = .loading
        }

        repository.fetchFavourites { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let movies):
                self.movies = movies
                self.state = movies.isEmpty ? .empty : .loaded

            case .failure(_):
                self.movies = []
                self.state = .empty
            }
        }
    }

    func removeFavourite(movie: Movie) {
        // Уведомление NotificationCenter само вызовет fetchFavourites()
        repository.removeFavourite(movie: movie) {}
    }
}
