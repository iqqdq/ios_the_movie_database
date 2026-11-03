//
//  MockMovieRepository.swift
//  TheMovieDatabase
//
//  Created by Artur on 02.11.2026.
//

import Foundation
@testable import TheMovieDatabase

final class MockMovieRepository: MovieRepositoryProtocol {

    // Кэш
    var stubbedCacheResult: Result<PaginatedResponse<Movie>, APIError> =
        .success(
            PaginatedResponse(
                page: 1,
                results: [],
                totalPages: 1,
                totalResults: 0
            )
        )

    // Сеть
    var stubbedNetworkResult: Result<PaginatedResponse<Movie>, APIError>!

    // Избранное
    var stubbedFavouriteIDs: Set<Int> = []
    
    // Поиск
    var searchMovieCallCount = 0

    func fetchPopular(
        page: Int,
        completion:
            @escaping (Result<PaginatedResponse<Movie>, APIError>, FetchSource)
            -> Void
    ) {
        // Сначала отдаем кэш (синхронно)
        completion(stubbedCacheResult, .cache)

        // Потом сеть (синхронно, чтобы тест сразу проверил результат)
        if let network = stubbedNetworkResult {
            completion(network, .network)
        }
    }

    func fetchFavouriteIDs(completion: @escaping (Set<Int>) -> Void) {
        completion(stubbedFavouriteIDs)
    }

    func searchMovie(
        page: Int,
        query: String,
        completion:
            @escaping (Result<PaginatedResponse<Movie>, APIError>) -> Void
    ) {
        // Увеличиваем счетчик при каждом вызове
        searchMovieCallCount += 1

        // Для теста поиска просто вернем пустой успешный ответ
        let emptyResponse = PaginatedResponse(
            page: 1,
            results: [Movie](),
            totalPages: 1,
            totalResults: 0
        )
        
        completion(.success(emptyResponse))
    }
    
    // Заглушки

    func fetchFavourites(
        completion: @escaping (Result<[Movie], APIError>) -> Void
    ) {}

    func saveFavourite(movie: Movie, completion: @escaping () -> Void) {}

    func removeFavourite(movie: Movie, completion: @escaping () -> Void) {ˆ}
}
