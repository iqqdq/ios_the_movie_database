//
//  SearchViewMofrlTests.swift
//  TheMovieDatabase
//
//  Created by Artur on 02.11.2026.
//

import XCTest
@testable import TheMovieDatabase

@MainActor
final class SearchViewModelTests: XCTestCase {

    var viewModel: SearchViewModel!
    var mockRepository: MockMovieRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockMovieRepository()
        viewModel = SearchViewModel(repository: mockRepository)
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Search Movie (Debounce)

    func testSearchDebounce_ShouldOnlyCallRepositoryOnce() {
        // 1. GIVEN
        // Изначально счетчик равен 0
        XCTAssertEqual(mockRepository.searchMovieCallCount, 0)

        // 2. WHEN
        // Пользователь быстро печатает "B", потом "Ba", потом "Bat"
        viewModel.searchMovie(query: "B")
        viewModel.searchMovie(query: "Ba")
        viewModel.searchMovie(query: "Bat")

        // В этот момент запросы еще не ушли (работает дебаунс 0.5 сек)
        XCTAssertEqual(
            mockRepository.searchMovieCallCount,
            0,
            "Запрос не должен уйти мгновенно"
        )

        // 3. Ждем, пока дебаунс отработает (0.5 сек + запас)
        let expectation = XCTestExpectation(description: "Ждем дебаунс")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)

        // 4. THEN
        // Вьюмодель должна была сделать только один запрос (для "Bat")
        XCTAssertEqual(
            mockRepository.searchMovieCallCount,
            1,
            "Должен быть выполнен только 1 запрос из-за дебаунса"
        )
    }
}
