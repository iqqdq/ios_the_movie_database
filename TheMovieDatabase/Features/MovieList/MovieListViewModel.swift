//
//  MovieListViewModel.swift
//  TheMovieDatabase
//
//  Created by Artur on 05.10.2026.
//

import Foundation

final class MovieListViewModel {

    // MARK: - State

    enum State {
        case idle
        case loading
        case loadingMore
        case refreshing
        case loaded
        case empty
        case error(String)
        case loadMoreError(String)
    }

    // MARK: - Output

    private(set) var state: State = .idle {
        didSet { onStateChanged?(state) }
    }

    private(set) var movies: [Movie] = []

    var onStateChanged: ((State) -> Void)?

    // MARK: - Private state

    private var nextPage: Int = 1
    private var totalPages: Int = 1
    private var isLoading: Bool = false
    private var isRefreshing: Bool = false
    private var shouldStopPagination: Bool = false

    private var canLoadMore: Bool {
        !isLoading
            && !isRefreshing
            && !shouldStopPagination
            && nextPage <= totalPages
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

        let isInitialLoad = nextPage == 1
        state = isInitialLoad ? .loading : .loadingMore

        loadPage(nextPage) { [weak self] result in
            guard let self else { return }
            self.isLoading = false

            switch result {
            case .success(let response):
                self.nextPage += 1
                self.totalPages = response.totalPages
                self.movies.append(contentsOf: response.results)
                self.state = self.movies.isEmpty ? .empty : .loaded

            case .failure(let error):
                print("❌ fetchMovies: \(error.errorDescription ?? "Unknown")")
                if isInitialLoad {
                    self.state = .error(error.userMessage)
                } else {
                    self.shouldStopPagination = true
                    self.state = .loadMoreError(error.userMessage)
                }
            }
        }
    }

    func refreshMovies() {
        guard !isLoading, !isRefreshing else {
            state = movies.isEmpty ? .empty : .loaded
            return
        }
        isRefreshing = true
        state = .refreshing

        loadPage(1) { [weak self] result in
            guard let self else { return }
            self.isRefreshing = false

            switch result {
            case .success(let response):
                self.nextPage = 2
                self.totalPages = response.totalPages
                self.movies = response.results
                self.shouldStopPagination = false
                self.state = self.movies.isEmpty ? .empty : .loaded

            case .failure(let error):
                print("❌ refreshMovies: \(error.errorDescription ?? "Unknown")")
                // Если данные уже есть — не показываем ошибку, остаёмся в .loaded
                if self.movies.isEmpty {
                    self.state = .error(error.userMessage)
                } else {
                    self.state = .loaded
                }
            }
        }
    }

    func retryLoadMore() {
        shouldStopPagination = false
        fetchMovies()
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
