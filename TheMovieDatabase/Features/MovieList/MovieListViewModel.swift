//
//  MovieListViewModel.swift
//  TheMovieDatabase
//
//  Created by Artur on 05.10.2026.
//

import Foundation

final class MovieListViewModel {

    // MARK: - Output

    private(set) var movies: [Movie] = []
    private(set) var isLoading: Bool = false

    var onMoviesUpdated: (() -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?
    var onLoadingMoreChanged: ((Bool) -> Void)?
    var onError: ((APIError) -> Void)?

    // MARK: - State

    private var currentPage: Int = 1
    private var totalPages: Int = 1

    // MARK: - Dependencies

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    // MARK: - Output

    func fetchMovies() {
        guard !isLoading else { return }
        guard currentPage <= totalPages else { return }

        isLoading = true
        currentPage == 0 ? onLoadingChanged?(true) : onLoadingMoreChanged?(true)

        let endpoint = Endpoint(
            path: Constants.moviePopular,
            queryItems: [URLQueryItem(name: "page", value: "\(currentPage)")]
        )

        apiClient.get(
            endpoint: endpoint,
            response: PaginatedResponse<Movie>.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                
                self.isLoading = false
                self.onLoadingChanged?(false)
                self.onLoadingMoreChanged?(false)

                switch result {
                case .success(let response):
                    self.currentPage += 1
                    self.totalPages = response.totalPages
                    self.movies.append(contentsOf: response.results)
                    self.onMoviesUpdated?()
                case .failure(let error):
                    self.onError?(error)
                }
            }
        }
    }
}
