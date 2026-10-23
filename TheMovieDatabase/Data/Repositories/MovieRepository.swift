//
//  MovieRepository.swift
//  TheMovieDatabase
//
//  Created by Artur on 13.10.2026.
//

import Foundation

protocol MovieRepositoryProtocol {
    func fetchPopular(
        page: Int,
        completion:
            @escaping (Result<PaginatedResponse<Movie>, APIError>) -> Void
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
            @escaping (Result<PaginatedResponse<Movie>, APIError>) -> Void
    ) {

        // 1. Сначала берем из кэша
        movieCacheStorage.fetchPopular(page: page) { [weak self] movies in
            guard let self else { return }

            // Если в кэше что-то есть — сразу отдаем в UI
            if !movies.isEmpty {
                let response = PaginatedResponse(
                    page: page,
                    results: movies,
                    totalPages: 1,  // Кэш не знает общего числа страниц
                    totalResults: movies.count
                )

                DispatchQueue.main.async {
                    completion(.success(response))
                }
            }

            // 2. Параллельно запрашиваем API
            let endpoint = Endpoint(
                path: Constants.moviePopular,
                queryItems: [URLQueryItem(name: "page", value: "\(page)")]
            )

            self.apiClient.get(
                endpoint: endpoint,
                response: PaginatedResponse<Movie>.self
            ) { [weak self] result in
                switch result {
                case .success(let response):
                    // Сохраняем свежие данные в кэш
                    self?.movieCacheStorage.savePopular(
                        response.results,
                        page: page
                    ) {
                        DispatchQueue.main.async {
                            completion(.success(response))
                        }
                    }

                case .failure(let error):
                    // Если сеть упала, но кэш был пуст — отдаем ошибку.
                    // Если кэш был — мы уже отдали его выше, ошибку игнорируем.
                    if movies.isEmpty {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
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
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    // MARK: - Favourite

    func fetchFavouriteIDs(completion: @escaping (Set<Int>) -> Void) {
        favouriteMovieCacheStorage.fetchFavouriteIDs { ids in
            DispatchQueue.main.async {
                completion(ids)
            }
        }
    }

    func fetchFavourites(
        completion:
            @escaping (Result<[Movie], APIError>) -> Void
    ) {
        favouriteMovieCacheStorage.fetchFavourites { movies in
            DispatchQueue.main.async {
                completion(.success(movies))
            }
        }
    }

    func saveFavourite(movie: Movie, completion: @escaping () -> Void) {
        favouriteMovieCacheStorage.saveFavourite(movie) {
            DispatchQueue.main.async {
                // Уведомляем все приложение, что избранное изменилось
                NotificationCenter.default.post(
                    name: .favouritesDidChange,
                    object: nil
                )
                completion()
            }
        }
    }

    func removeFavourite(movie: Movie, completion: @escaping () -> Void) {
        favouriteMovieCacheStorage.removeFavourite(movie) {
            DispatchQueue.main.async {
                // Уведомляем все приложение, что избранное изменилось
                NotificationCenter.default.post(
                    name: .favouritesDidChange,
                    object: nil
                )
                completion()
            }
        }
    }
}
