//
//  PopularViewModel.swift
//  TheMovieDatabase
//
//  Created by Artur on 05.10.2026.
//

import Foundation

final class PopularViewModel {

    // MARK: - Dependencies

    private let repository: MovieRepositoryProtocol

    // MARK: - Observers

    private var favouriteObserver: NSObjectProtocol?

    // MARK: - Output

    private(set) var movies: [Movie] = []
    private(set) var favouriteIDs: Set<Int> = []
    private(set) var state: PopularState = .idle {
        didSet {
            onStateChanged?(state)
        }
    }

    var onStateChanged: ((PopularState) -> Void)?
    var onFavouritesChanged: (() -> Void)?

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

    // MARK: - Popular

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

        // Обновляем ID's избранных
        if isFirstPage {
            fetchFavouritesIDs()
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

                let newState: PopularState =
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
        
        // Обновляем ID's избранных
        fetchFavouritesIDs()

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
