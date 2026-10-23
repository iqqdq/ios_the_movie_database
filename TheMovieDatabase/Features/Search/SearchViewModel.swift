//
//  SearchViewModel.swift
//  TheMovieDatabase
//
//  Created by Artur on 14.10.2026.
//

import Foundation

final class SearchViewModel {

    // MARK: - Output

    private var favouriteObserver: NSObjectProtocol?

    private(set) var movies: [Movie] = []
    private(set) var favouriteIDs: Set<Int> = []
    private(set) var state: SearchState = .idle {
        didSet {
            onStateChanged?(state)
        }
    }

    var onStateChanged: ((SearchState) -> Void)?
    var onFavouritesChanged: (() -> Void)?

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

        // Подписываемся на изменения избранного
        favouriteObserver = NotificationCenter.default.addObserver(
            forName: .favouritesDidChange,
            object: nil,
            queue: .main,
            using: { [weak self] _ in
                self?.fetchFavouritesIDs()
            }
        )
    }

    deinit {
        if let observer = favouriteObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
        
        // Обновляем ID's избранных
        fetchFavouritesIDs()

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

    // MARK: Favourites

    private func fetchFavouritesIDs() {
        repository.fetchFavouriteIDs { [weak self] ids in
            guard let self else { return }
            self.favouriteIDs = ids
            self.onFavouritesChanged?()
        }
    }

    func isFavourite(_ id: Int) -> Bool {
        return favouriteIDs.contains(id)
    }

    func toggleFavourite(movie: Movie) {
        if isFavourite(movie.id) {
            repository.removeFavourite(movie: movie) { [weak self] in
                guard let self else { return }
                self.favouriteIDs.remove(movie.id)
                self.onFavouritesChanged?()
            }
        } else {
            repository.saveFavourite(movie: movie) { [weak self] in
                guard let self else { return }
                self.favouriteIDs.insert(movie.id)
                self.onFavouritesChanged?()
            }
        }
    }
}
