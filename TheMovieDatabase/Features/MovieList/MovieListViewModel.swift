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
    private var isLoading: Bool = false
    private var isRefreshing: Bool = false

    var onLoadingChanged: ((Bool) -> Void)?
    var onLoadingMoreChanged: ((Bool) -> Void)?
    var onMoviesUpdated: (() -> Void)?
    var onRefreshFinished: (() -> Void)?
    var onError: ((APIError) -> Void)?

    // MARK: - State

    private var nextPage: Int = 1
    private var totalPages: Int = 1
    private var canLoadMore: Bool {
        !isLoading && !isRefreshing && nextPage <= totalPages
    }

    // MARK: - Dependencies

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    // MARK: - Public

    func fetchMovies() {
        guard canLoadMore else { return }
        isLoading = true

        let isInitialLoad = movies.isEmpty
        if isInitialLoad {
            onLoadingChanged?(true)
        } else {
            onLoadingMoreChanged?(true)
        }

        loadPage(nextPage) { [weak self] result in
            guard let self else { return }

            self.isLoading = false

            if isInitialLoad {
                self.onLoadingChanged?(false)
            } else {
                self.onLoadingMoreChanged?(false)
            }

            switch result {
            case .success(let response):
                self.nextPage += 1
                self.totalPages = response.totalPages
                self.movies.append(contentsOf: response.results)
                self.onMoviesUpdated?()
            case .failure(let error):
                self.onError?(error)
            }
        }
    }

    func refreshMovies() {
        guard !isLoading, !isRefreshing else {
            onRefreshFinished?()
            return
        }
        isRefreshing = true
        
        loadPage(1) { [weak self] result in
            guard let self else { return }

            self.isRefreshing = false
            self.onRefreshFinished?()

            switch result {
            case .success(let response):
                self.nextPage = 2
                self.totalPages = response.totalPages
                self.movies = response.results
                self.onMoviesUpdated?()
            case .failure(let error):
                self.onError?(error)
            }
        }
    }

    // MARK: - Private

    private func loadPage(
        _ page: Int,
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
