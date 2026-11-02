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

    // MARK: - Private

    private func fetchFavouritesIDs() {
        repository.fetchFavouriteIDs { [weak self] ids in
            DispatchQueue.main.async {
                guard let self else { return }
                self.favouriteIDs = ids
                self.onFavouritesChanged?()
            }
        }
    }

    // Применяет ответ к списку
    // Первая страница заменяет данные, остальные — добавляются
    private func apply(
        _ response: PaginatedResponse<Movie>,
        isFirstPage: Bool
    ) {
        totalPages = response.totalPages

        if isFirstPage {
            movies = response.results
            nextPage = 2
        } else {
            movies.append(contentsOf: response.results)
            nextPage += 1
        }
    }

    // MARK: - Public

    func fetchMovies() {
        guard canLoadMore else { return }

        let pageToLoad = nextPage
        let isFirstPage = pageToLoad == 1

        isLoading = true

        // Лоадер заранее не показываем: сначала ждём ответ кэша.
        // Если кэш пуст — лоадер включится в обработчике .cache.
        // При пагинации показываем спиннер в футере таблицы.
        if isFirstPage {
            if !movies.isEmpty {
                state = .loaded
            }
        } else {
            state = .loadingMore
        }

        if isFirstPage {
            fetchFavouritesIDs()
        }

        repository.fetchPopular(page: pageToLoad) { [weak self] result, source in
            DispatchQueue.main.async {
                guard let self else { return }

                switch source {
                case .cache:
                    // Кэш применяем только для первой страницы.
                    // На пагинации кэш и сеть добавили бы страницу дважды.
                    guard isFirstPage else { return }
                    guard case .success(let response) = result else { return }

                    // Пустой кэш не должен затирать уже показанные данные.
                    if response.results.isEmpty && !self.movies.isEmpty {
                        return
                    }

                    self.apply(response, isFirstPage: true)

                    // Есть кэш — показываем его сразу и без лоадера,
                    // сеть продолжает работать втихую.
                    // Кэш пуст — только теперь показываем лоадер.
                    // isLoading не снимаем: сеть ещё в полёте,
                    // поэтому повторный fetch/refresh не запустится.
                    self.state = self.movies.isEmpty ? .loading : .loaded

                case .network:
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        self.apply(response, isFirstPage: isFirstPage)
                        let newState: PopularState = self.movies.isEmpty ? .empty : .loaded
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
                        } else {
                            // Первая страница, но данные уже есть (кэш).
                            // Остаёмся в .loaded и уведомляем UI,
                            // чтобы завершить возможный refresh.
                            self.onStateChanged?(self.state)
                        }
                    }
                }
            }
        }
    }

    func refreshMovies() {
        guard !isLoading, !isRefreshing else {
            // Уже идёт загрузка — второй запрос не нужен.
            // Состояние не трогаем, чтобы не спрятать лоадер
            // и не показать пустой экран раньше времени.
            return
        }

        isRefreshing = true

        // .refreshing не показывает центральный лоадер.
        // Если кэш есть — покажем его сразу, а если пуст —
        // лоадер включится после ответа кэша.
        state = .refreshing

        // Обновляем ID's избранных
        fetchFavouritesIDs()

        repository.fetchPopular(page: 1) { [weak self] result, source in
            DispatchQueue.main.async {
                guard let self else { return }

                switch source {
                case .cache:
                    guard case .success(let response) = result else { return }

                    // Если данные уже есть, кэш не подставляем,
                    // чтобы таблица не мигала.
                    guard self.movies.isEmpty else { return }

                    if response.results.isEmpty {
                        // Кэша нет — показываем лоадер до ответа сети.
                        self.state = .loading
                    } else {
                        // Кэш есть — показываем сразу, сеть работает втихую.
                        self.apply(response, isFirstPage: true)
                        self.state = .loaded
                    }

                case .network:
                    self.isRefreshing = false

                    switch result {
                    case .success(let response):
                        self.apply(response, isFirstPage: true)
                        self.shouldStopPagination = false
                        self.state = self.movies.isEmpty ? .empty : .loaded
                    case .failure(let error):
                        if self.movies.isEmpty {
                            self.state = .error(error.userMessage)
                        } else {
                            self.state = .loaded
                        }
                    }
                }
            }
        }
    }

    func retryLoadMore() {
        shouldStopPagination = false
        fetchMovies()
    }

    func isFavourite(_ id: Int) -> Bool {
        return favouriteIDs.contains(id)
    }

    func toggleFavourite(movie: Movie) {
        if isFavourite(movie.id) {
            repository.removeFavourite(movie: movie) { [weak self] in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.favouriteIDs.remove(movie.id)
                    self.onFavouritesChanged?()
                }
            }
        } else {
            repository.saveFavourite(movie: movie) { [weak self] in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.favouriteIDs.insert(movie.id)
                    self.onFavouritesChanged?()
                }
            }
        }
    }
}
