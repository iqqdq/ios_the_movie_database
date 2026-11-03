import CoreData
import XCTest

@testable import TheMovieDatabase

final class MovieCacheStorageTests: XCTestCase {

    var stack: CoreDataStack!
    var storage: MovieCacheStorage!

    override func setUp() {
        super.setUp()
        // Создаем БД в памяти для тестов
        stack = CoreDataStack(inMemory: true)
        storage = MovieCacheStorage(stack: stack)
    }

    override func tearDown() {
        storage = nil
        stack = nil
        super.tearDown()
    }

    func testSavePopular_Success() {
        // 1. GIVEN
        // Моковые фильмы для записи в БД
        let first = Movie(
            id: 1,
            title: "First Movie",
            overview: "",
            posterPath: nil,
            releaseDate: "",
            voteAverage: 1.0,
            voteCount: 10
        )

        let second = Movie(
            id: 2,
            title: "Second Movie",
            overview: "",
            posterPath: nil,
            releaseDate: "",
            voteAverage: 2.0,
            voteCount: 20
        )

        let third = Movie(
            id: 3,
            title: "Third Movie",
            overview: "",
            posterPath: nil,
            releaseDate: "",
            voteAverage: 3.0,
            voteCount: 30
        )

        let expectationSave = XCTestExpectation(
            description:
                "Запись в БД"
        )

        // 2. WHEN
        // Записываем фильмы в БД
        storage.savePopular(
            [first, second, third],
            page: 1
        ) {
            expectationSave.fulfill()
        }

        wait(for: [expectationSave], timeout: 1.0)

        // 3. THEN
        // Проверяем, что фильмы записались в БД
        let expectationFetch = XCTestExpectation(
            description:
                "Чтение из БД"
        )

        var storageMovies: [Movie] = []

        storage.fetchPopular(page: 1) { result in
            storageMovies = result
            expectationFetch.fulfill()
        }

        wait(for: [expectationFetch], timeout: 1.0)

        XCTAssertEqual(storageMovies.count, 3)
    }
}
