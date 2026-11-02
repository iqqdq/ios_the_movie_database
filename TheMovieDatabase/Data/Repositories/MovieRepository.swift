//
//  MovieRepository.swift
//  TheMovieDatabase
//
//  Created by Artur on 13.10.2026.
//

import Foundation

// Источник, из которого пришли данные.
// .cache приходит всегда, даже пустой: по нему ViewModel решает,
// показать кэш сразу или включить лоадер.
// .network завершает загрузку — по нему снимаются флаги.
enum FetchSource {
    case cache
    case network
}

protocol MovieRepositoryProtocol {
    func fetchPopular(
        page: Int,
        completion:
            @escaping (
                Result<PaginatedResponse<Movie>, APIError>,
                FetchSource
            ) -> Void
    )

    func searchMovie(
        page: Int,
        query: String,
        completion:
            @escaping (Result<PaginatedResponse<Movie>, APIError>) -> Void
    )

    func fetchFavouriteIDs(
        completion:
            @escaping (Set<Int>) -> Void
    )

    func fetchFavourites(
        completion:
            @escaping (Result<[Movie], APIError>) -> Void
    )

    func saveFavourite(movie: Movie, completion: @escaping () -> Void)
    func removeFavourite(movie: Movie, completion: @escaping () -> Void)
}

final class MovieRepository: MovieRepositoryProtocol {

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let movieCacheStorage: MovieCacheStorageProtocol
    private let favouriteMovieCacheStorage: FavouriteMovieCacheStorageProtocol

    // MARK: - Init

    init(
        apiClient: APIClient = .shared,
        movieCacheStorage: MovieCacheStorageProtocol = MovieCacheStorage(),
        favouriteMovieCacheStorage: FavouriteMovieCacheStorageProtocol =
            FavouriteMovieCacheStorage()
    ) {
        self.apiClient = apiClient
        self.movieCacheStorage = movieCacheStorage
        self.favouriteMovieCacheStorage = favouriteMovieCacheStorage
    }

    // MARK: - Popular

    func fetchPopular(
        page: Int,
        completion:
            @escaping (
                Result<PaginatedResponse<Movie>, APIError>,
                FetchSource
            ) -> Void
    ) {

        // 1. Сначала читаем кэш.
        movieCacheStorage.fetchPopular(page: page) { [weak self] movies in
            guard let self else { return }

            let cachedResponse = PaginatedResponse(
                page: page,
                results: movies,
                totalPages: 1,  // Кэш не знает общего числа страниц
                totalResults: movies.count
            )

            // Отдаём результат кэша ВСЕГДА, даже если он пустой.
            // Так ViewModel понимает, показывать лоадер или нет:
            // есть кэш — показываем данные, пусто — показываем лоадер.
            completion(.success(cachedResponse), .cache)

            // 2. Параллельно запрашиваем API.
            let endpoint = Endpoint(
                path: Constants.moviePopular,
                queryItems: [URLQueryItem(name: "page", value: "\(page)")]
            )

            self.apiClient.get(
                endpoint: endpoint,
                response: PaginatedResponse<Movie>.self
            ) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success(let response):
                    // Сохраняем свежие данные в кэш и только потом
                    // сообщаем ViewModel, что сеть завершилась.
                    self.movieCacheStorage.savePopular(
                        response.results,
                        page: page
                    ) {
                        completion(.success(response), .network)
                    }

                case .failure(let error):
                    // Даже если кэш уже отдан, сеть обязана сообщить
                    // о завершении: иначе isLoading останется true.
                    completion(.failure(error), .network)
                }
            }
        }
    }

    // MARK: - Search

    func searchMovie(
        page: Int,
        query: String,
        completion:
            @escaping (Result<PaginatedResponse<Movie>, APIError>) -> Void
    ) {
        let endpoint = Endpoint(
            path: Constants.searchMovie,
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "query", value: "\(query)"),
            ]
        )

        apiClient.get(
            endpoint: endpoint,
            response: PaginatedResponse<Movie>.self
        ) { result in
            completion(result)

        }
    }

    // MARK: - Favourite

    func fetchFavouriteIDs(completion: @escaping (Set<Int>) -> Void) {
        favouriteMovieCacheStorage.fetchFavouriteIDs { ids in
            completion(ids)
        }
    }

    func fetchFavourites(
        completion:
            @escaping (Result<[Movie], APIError>) -> Void
    ) {
        favouriteMovieCacheStorage.fetchFavourites { movies in
            completion(.success(movies))
        }
    }

    func saveFavourite(movie: Movie, completion: @escaping () -> Void) {
        favouriteMovieCacheStorage.saveFavourite(movie) {
            // Уведомляем все приложение, что избранное изменилось
            NotificationCenter.default.post(
                name: .favouritesDidChange,
                object: nil
            )
            completion()
        }
    }

    func removeFavourite(movie: Movie, completion: @escaping () -> Void) {
        favouriteMovieCacheStorage.removeFavourite(movie) {
            // Уведомляем все приложение, что избранное изменилось
            NotificationCenter.default.post(
                name: .favouritesDidChange,
                object: nil
            )
            completion()
        }
    }
}
