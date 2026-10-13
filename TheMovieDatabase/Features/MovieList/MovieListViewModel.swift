//
//  MovieListViewModel.swift
//  TheMovieDatabase
//
//  Created by Artur on 05.10.2026.
//

import Foundation

final class MovieListViewModel {

    // MARK: - Output

    private(set) var state: MovieListState = .idle {
        didSet { onStateChanged?(state) }
    }

    private(set) var movies: [Movie] = []

    var onStateChanged: ((MovieListState) -> Void)?

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

    private let repository: MovieRepositoryProtocol

    init(repository: MovieRepositoryProtocol = MovieRepository()) {
        self.repository = repository
    }

    // MARK: - Public

    func fetchMovies() {
        guard canLoadMore else { return }
        isLoading = true

        let isInitialLoad = nextPage == 1
        state = isInitialLoad ? .loading : .loadingMore

        repository.fetchPopular(page: nextPage) { [weak self] result in
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
                    self.state = .loadMoreError
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

        repository.fetchPopular(page: 1) { [weak self] result in
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
}
