//
//  MovieRepository.swift
//  TheMovieDatabase
//
//  Created by Artur on 13.10.2026.
//

import Foundation

final class MovieRepository: MovieRepositoryProtocol {

    // MARK: - Dependencies

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    // MARK: - MovieRepositoryProtocol

    func fetchPopular(
        page: Int,
        completion:
            @escaping (Result<PaginatedResponse<Movie>, APIError>) -> Void
    ) {
        let endpoint = Endpoint(
            path: Constants.moviePopular,
            queryItems: [URLQueryItem(name: "page", value: "\(page)")]
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
