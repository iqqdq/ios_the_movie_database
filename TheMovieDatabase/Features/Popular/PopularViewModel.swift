//
//  PopularViewModel.swift
//  TheMovieDatabase
//
//  Created by Artur on 05.10.2026.
//

import Foundation

final class PopularViewModel {

    // MARK: - Output

    private(set) var state: PopularListState = .idle {
        didSet {
            onStateChanged?(state)
        }
    }

    private(set) var movies: [Movie] = []

    var onStateChanged: ((PopularListState) -> Void)?

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

        // Запоминаем, какую страницу мы запрашиваем ПРЯМО СЕЙЧАС
        let pageToLoad = nextPage
        let isFirstPage = pageToLoad == 1

        isLoading = true

        // Показываем спиннер только если это первая страница и данных еще нет
        if isFirstPage {
            state = .loading
        } else {
            state = .loadingMore
        }

        repository.fetchPopular(page: pageToLoad) { [weak self] result in
            guard let self else { return }
            self.isLoading = false

            switch result {
            case .success(let response):
                self.totalPages = response.totalPages

                if isFirstPage {
                    // Если это первая страница, мы ЗАМЕНЯЕМ старые данные новыми
                    self.movies = response.results
                    self.nextPage = 2
                } else {
                    // Если это пагинация, мы ДОБАВЛЯЕМ данные
                    self.movies.append(contentsOf: response.results)
                    self.nextPage += 1
                }

                let newState: PopularListState =
                    self.movies.isEmpty ? .empty : .loaded

                // ВАЖНО: Так как кэш и сеть присылают ответ дважды,
                // state может не измениться (был .loaded, стал .loaded).
                // Чтобы таблица перерисовалась, вызываем принудительно.
                if newState != self.state {
                    self.state = newState
                } else {
                    self.onStateChanged?(self.state)
                }

            case .failure(let error):
                if isFirstPage && self.movies.isEmpty {
                    self.state = .error(error.userMessage)
                } else if !isFirstPage {
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
