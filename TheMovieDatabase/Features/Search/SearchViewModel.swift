//
//  SearchViewModel.swift
//  TheMovieDatabase
//
//  Created by Artur on 14.10.2026.
//

import Foundation

final class SearchViewModel {

    // MARK: - Output

    private(set) var state: SearchState = .idle {
        didSet {
            onStateChanged?(state)
        }
    }

    private(set) var movies: [Movie] = []

    var onStateChanged: ((SearchState) -> Void)?

    // MARK: - Private state

    private var nextPage: Int = 1
    private var totalPages: Int = 1
    private var isLoading: Bool = false
    private var shouldStopPagination: Bool = false
    private var currentQuery: String = ""

    private var searchWorkItem: DispatchWorkItem?

    private var canLoadMore: Bool {
        !isLoading
            && !shouldStopPagination
            && nextPage <= totalPages
    }

    // MARK: - Dependencies

    private let repository: MovieRepositoryProtocol

    init(repository: MovieRepositoryProtocol = MovieRepository()) {
        self.repository = repository
    }

    // MARK: - Public

    /// Вызывается на каждое изменение текста в поисковой строке.
    /// Дебаунсит ввод: реальный запрос уйдёт только после паузы.
    func searchMovie(query: String) {
        searchWorkItem?.cancel()

        guard !query.isEmpty else {
            resetSearch()
            state = .idle
            onStateChanged?(.idle)
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.performSearch(query: query)
        }
        searchWorkItem = workItem

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.5,
            execute: workItem
        )
    }

    /// Вызывается при скролле к низу списка.
    /// Подгружает следующую страницу для текущего запроса.
    func loadMore() {
        guard canLoadMore else { return }

        let query = currentQuery

        isLoading = true
        state = .loadingMore

        repository.searchMovie(page: nextPage, query: query) {
            [weak self] result in
            guard let self else { return }
            self.isLoading = false

            switch result {
            case .success(let response):
                guard query == self.currentQuery else { return }

                self.nextPage += 1
                self.totalPages = response.totalPages
                self.movies.append(contentsOf: response.results)
                self.state = .results

            case .failure(let error):
                guard query == self.currentQuery else { return }

                print("❌ loadMore: \(error.errorDescription ?? "Unknown")")
                self.shouldStopPagination = true
                self.state = .loadMoreError
            }
        }
    }

    /// Повторная попытка загрузить страницу после ошибки пагинации.
    func retryLoadMore() {
        shouldStopPagination = false
        loadMore()
    }

    // MARK: - Private

    /// Реальный поиск. Вызывается только через `search(query:)` после debounce.
    private func performSearch(query: String) {
        resetSearch()
        currentQuery = query

        isLoading = true
        state = .searching

        repository.searchMovie(page: 1, query: query) {
            [weak self] result in
            guard let self else { return }
            self.isLoading = false

            switch result {
            case .success(let response):
                guard query == self.currentQuery else { return }

                self.nextPage = 2
                self.totalPages = response.totalPages
                self.movies = response.results
                self.state = self.movies.isEmpty ? .empty : .results

            case .failure(let error):
                guard query == self.currentQuery else { return }

                print("❌ search: \(error.errorDescription ?? "Unknown")")
                self.state = .error(error.userMessage)
            }
        }
    }

    private func resetSearch() {
        movies.removeAll()
        nextPage = 1
        totalPages = 1
        shouldStopPagination = false
        isLoading = false
        currentQuery = ""
    }
}
