//
//  PopularViewModelTests.swift
//  TheMovieDatabase
//
//  Created by Artur on 02.11.2026.
//

import XCTest
@testable import TheMovieDatabase

@MainActor
final class PopularViewModelTests: XCTestCase {

    var viewModel: PopularViewModel!
    var mockRepository: MockMovieRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockMovieRepository()
        viewModel = PopularViewModel(repository: mockRepository)
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Fetch Movies Success

    func testFetchMovies_Success() {
        // 1. GIVEN
        // Пустой кэш, успешная сеть
        mockRepository.stubbedCacheResult = .success(
            PaginatedResponse(
                page: 1,
                results: [],
                totalPages: 1,
                totalResults: 0
            )
        )

        let movie = Movie(
            id: 1,
            title: "Test Movie",
            overview: "",
            posterPath: nil,
            releaseDate: "",
            voteAverage: 5.0,
            voteCount: 10
        )

        let networkResponse = PaginatedResponse(
            page: 1,
            results: [movie],
            totalPages: 1,
            totalResults: 1
        )

        mockRepository.stubbedNetworkResult = .success(networkResponse)

        // 2. WHEN
        // Запрашиваем список фильмов
        viewModel.fetchMovies()

        let expectation = XCTestExpectation(
            description:
                "Ждем пока viewModel.fetchMovies вернет результат в main queue"
        )
        
        DispatchQueue.main.async {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // 3. THEN
        // Проверяем, что вернулся 1 фильм из сети (кэш пустой)
        // Меняем состояние окна на .loaded
        XCTAssertEqual(viewModel.movies.count, 1)
        XCTAssertEqual(viewModel.movies.first?.title, "Test Movie")
        XCTAssertEqual(viewModel.state, .loaded)
    }

    // MARK: - Fetch Movies Error

    func testFetchMovies_Failure_ShouldShowError() {
        // 1. GIVEN
        // Пустой кэш, ошибка сети
        mockRepository.stubbedCacheResult = .success(
            PaginatedResponse(
                page: 1,
                results: [],
                totalPages: 1,
                totalResults: 0
            )
        )
        mockRepository.stubbedNetworkResult = .failure(.invalidResponse)

        // 2. WHEN
        // Запрашиваем список фильмов
        viewModel.fetchMovies()

        let expectation = XCTestExpectation(
            description:
                "Ждем пока viewModel.fetchMovies вернет результат в main queue"
        )
        
        DispatchQueue.main.async {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // 3. THEN
        // Проверяем, что список пуст - возвращаем ошибку
        XCTAssertTrue(viewModel.movies.isEmpty)

        switch viewModel.state {
        case .error: break
        default: XCTFail("viewModel.state должно быть .error")
        }
    }

    // MARK: - Toggle Favourite

    func testToggleFavourite_ShouldUpdateSet() {
        // 1. GIVEN
        // Фильм, которого нет в "избранном"
        let movie = Movie(
            id: 99,
            title: "Fav Movie",
            overview: "",
            posterPath: nil,
            releaseDate: "",
            voteAverage: 0,
            voteCount: 0
        )

        XCTAssertFalse(viewModel.isFavourite(99))

        // 2. WHEN
        // Добавляем в "избранное"
        viewModel.toggleFavourite(movie: movie)

        let expectation = XCTestExpectation(
            description:
                "Ждем пока viewModel.toggleFavourite вернет результат в main queue"
        )
        
        DispatchQueue.main.async {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // 3. THEN
        // Проверяем, что фильм теперь в "избранном"
        XCTAssertTrue(viewModel.isFavourite(99))
    }
}
