//
//  SettingsRepository.swift
//  TheMovieDatabase
//
//  Created by Artur on 23.10.2026.
//

import Foundation

protocol SettingsRepositoryProtocol {
    func clearCache(completion: @escaping () -> Void)
    func clearFavourites(completion: @escaping () -> Void)
}

final class SettingsRepository: SettingsRepositoryProtocol {

    private let movieCacheStorage: MovieCacheStorageProtocol
    private let favouriteMovieCacheStorage: FavouriteMovieCacheStorageProtocol

    init(
        movieCacheStorage: MovieCacheStorageProtocol = MovieCacheStorage(),
        favouriteMovieCacheStorage: FavouriteMovieCacheStorageProtocol =
            FavouriteMovieCacheStorage()
    ) {
        self.movieCacheStorage = movieCacheStorage
        self.favouriteMovieCacheStorage = favouriteMovieCacheStorage
    }

    func clearCache(completion: @escaping () -> Void) {
        movieCacheStorage.clear {
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func clearFavourites(completion: @escaping () -> Void) {
        favouriteMovieCacheStorage.clear {
            DispatchQueue.main.async {
                // Сообщаем всем экранам, что избранное опустело
                NotificationCenter.default.post(
                    name: .favouritesDidChange,
                    object: nil
                )
                completion()
            }
        }
    }
}
