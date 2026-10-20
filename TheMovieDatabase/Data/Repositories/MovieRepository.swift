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
}

final class MovieRepository: MovieRepositoryProtocol {

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let cacheStorage: MovieCacheStorageProtocol
    
    // MARK: - Init
    
    init(
        apiClient: APIClient = .shared,
        cacheStorage: MovieCacheStorageProtocol = MovieCacheStorage()
    ) {
        self.apiClient = apiClient
        self.cacheStorage = cacheStorage
    }

    // MARK: - MovieRepositoryProtocol

    
    func fetchPopular(page: Int, completion: @escaping (Result<PaginatedResponse<Movie>, APIError>) -> Void) {
        
        // 1. СНАЧАЛА БЕРЕМ ИЗ КЭША (Cache-first)
        cacheStorage.fetchPopular(page: page) { [weak self] cachedMovies in
            guard let self else { return }
            
            // Если в кэше что-то есть — сразу отдаем в UI
            if !cachedMovies.isEmpty {
                let cachedResponse = PaginatedResponse(
                    page: page,
                    results: cachedMovies,
                    totalPages: 1, // Кэш не знает общего числа страниц
                    totalResults: cachedMovies.count
                )
                // Отдаем на главном потоке
                DispatchQueue.main.async {
                    completion(.success(cachedResponse))
                }
            }
            
            // 2. ПАРАЛЛЕЛЬНО ИДЕМ В СЕТЬ
            let endpoint = Endpoint(
                path: Constants.moviePopular,
                queryItems: [URLQueryItem(name: "page", value: "\(page)")]
            )
            
            self.apiClient.get(
                endpoint: endpoint,
                response: PaginatedResponse<Movie>.self
            ) { [weak self] networkResult in
                switch networkResult {
                case .success(let response):
                    // Сохраняем свежие данные в кэш
                    self?.cacheStorage.savePopular(response.results, page: page) {
                        // И отдаем в UI
                        DispatchQueue.main.async {
                            completion(.success(response))
                        }
                    }
                    
                case .failure(let error):
                    // Если сеть упала, но кэш был пуст — отдаем ошибку.
                    // Если кэш был — мы уже отдали его выше, ошибку игнорируем.
                    if cachedMovies.isEmpty {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }
    
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
}
