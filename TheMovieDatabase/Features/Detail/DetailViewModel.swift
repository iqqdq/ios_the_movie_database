//
//  DetailViewModel.swift
//  TheMovieDatabase
//
//  Created by Artur on 23.10.2026.
//

import Foundation

final class DetailViewModel {

    // MARK: - Dependencies

    private let repository: MovieRepositoryProtocol

    // MARK: - Observers

    private var favouriteObserver: NSObjectProtocol?

    // MARK: - Output

    private let movie: Movie

    private(set) var isFavourite: Bool = false {
        didSet { onFavouriteStatusChanged?(isFavourite) }
    }

    var onFavouriteStatusChanged: ((Bool) -> Void)?

    // MARK: - Init

    init(movie: Movie, repository: MovieRepositoryProtocol = MovieRepository()) {
        self.movie = movie
        self.repository = repository

        // Подписываемся на изменения избранного
        favouriteObserver = NotificationCenter.default.addObserver(
            forName: .favouritesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkFavouriteStatus()
        }

        checkFavouriteStatus()
    }

    deinit {
        if let observer = favouriteObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public

    func toggleFavourite() {
        isFavourite.toggle()
        
        if isFavourite {
            repository.saveFavourite(movie: movie) {}
        } else {
            repository.removeFavourite(movie: movie) {}
        }
    }

    // MARK: - Private

    private func checkFavouriteStatus() {
        repository.fetchFavouriteIDs { [weak self] ids in
            guard let self else { return }
            
            let newStatus = ids.contains(self.movie.id)
            
            if self.isFavourite != newStatus {
                self.isFavourite = newStatus
            }
        }
    }
}
