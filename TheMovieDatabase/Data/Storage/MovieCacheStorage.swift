//
//  MovieCacheStorage.swift
//  TheMovieDatabase
//
//  Created by Artur on 20.10.2026.
//

import CoreData
import Foundation

protocol MovieCacheStorageProtocol {
    func fetchPopular(page: Int, completion: @escaping ([Movie]) -> Void)
    func savePopular(
        _ movies: [Movie],
        page: Int,
        completion: @escaping () -> Void
    )
    func clear(completion: @escaping () -> Void)
}

final class MovieCacheStorage: MovieCacheStorageProtocol {
    private let stack: CoreDataStack

    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }

    // MARK: - Fetch

    func fetchPopular(page: Int, completion: @escaping ([Movie]) -> Void) {
        let context = stack.viewContext
        context.perform {
            let request = MovieEntity.fetchRequest()
            // Фильтр: только нужная страница (page == N)
            request.predicate = NSPredicate(format: "page == %d", page)

            // Сортировка: строго по порядку (orderIndex)
            request.sortDescriptors = [
                NSSortDescriptor(key: "orderIndex", ascending: true)
            ]

            do {
                // Получаем массив объектов MovieEntity из базы
                let entities = try context.fetch(request)
                let movies = entities.compactMap { $0.toDomain() }
                completion(movies)
            } catch {
                print("Core Data popular fetch failed: \(error)")
                completion([])
            }
        }
    }

    // MARK: - Save

    func savePopular(
        _ movies: [Movie],
        page: Int,
        completion: @escaping () -> Void
    ) {
        let context = stack.newBackgroundContext()
        context.perform {
            // 1. Сначала УДАЛЯЕМ старые данные для этой страницы (чтобы не было дублей)
            let request = MovieEntity.fetchRequest()
            request.predicate = NSPredicate(format: "page == %d", page)

            do {
                let oldEntities = try context.fetch(request)
                for entity in oldEntities {
                    context.delete(entity)
                }

                // Создаем новые объекты
                for (index, movie) in movies.enumerated() {
                    _ = MovieEntity.fromDomain(
                        movie,
                        page: page,
                        orderIndex: index,
                        context: context
                    )
                }

                // Сохраняем в базу
                if context.hasChanges {
                    try context.save()
                }

                completion()
            } catch {
                print("Core Data popular save failed: \(error)")
                completion()
            }
        }
    }

    // MARK: - Clear

    func clear(completion: @escaping () -> Void) {
        let context = stack.newBackgroundContext()
        context.perform {
            let request = MovieEntity.fetchRequest()
            // Удаляем все записи
            let deleteRequest = NSBatchDeleteRequest(
                fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>
            )

            do {
                try context.execute(deleteRequest)
                // ВАЖНО: после Batch Delete нужно обновить главный контекст,
                // чтобы он "узнал" об удалениях
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: []],
                    into: [self.stack.viewContext]
                )

                completion()
            } catch {
                print("Core Data popular clear failed: \(error)")
                completion()
            }
        }
    }
}
