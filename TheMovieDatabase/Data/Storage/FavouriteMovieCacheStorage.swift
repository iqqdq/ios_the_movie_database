//
//  FavouriteMovieCacheStorage.swift
//  TheMovieDatabase
//
//  Created by Artur on 20.10.2026.
//

import CoreData
import Foundation

protocol FavouriteMovieCacheStorageProtocol {
    func fetchFavouriteIDs(completion: @escaping (Set<Int>) -> Void)
    func fetchFavourites(completion: @escaping ([Movie]) -> Void)
    func saveFavourite(_ movie: Movie, completion: @escaping () -> Void)
    func removeFavourite(_ movie: Movie, completion: @escaping () -> Void)
}

final class FavouriteMovieCacheStorage: FavouriteMovieCacheStorageProtocol {
    private let stack: CoreDataStack

    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }

    // MARK: - Fetch

    func fetchFavouriteIDs(completion: @escaping (Set<Int>) -> Void) {
        let context = stack.newBackgroundContext()
        context.perform {
            let request = FavouriteMovieEntity.fetchRequest()
            // Нам нужны ID's, чтобы определять избранные фильмы в окне Popular
            request.propertiesToFetch = ["id"]

            do {
                let entities = try context.fetch(request)
                let ids = Set(entities.map { Int($0.id) })
                completion(ids)
            } catch {
                print("Core Data fetch favourite ID's failed: \(error)")
                completion([])
            }
        }
    }

    func fetchFavourites(completion: @escaping ([Movie]) -> Void) {
        let context = stack.newBackgroundContext()
        context.perform {
            let request = FavouriteMovieEntity.fetchRequest()
            // Сортируем новые добавленные сверху
            request.sortDescriptors = [
                NSSortDescriptor(key: "addedAt", ascending: false)
            ]

            do {
                let entities = try context.fetch(request)
                let favourites = entities.compactMap { ($0.toDomain()) }
                completion(favourites)
            } catch {
                print("Core Data fetch favourites failed: \(error)")
                completion([])
            }
        }
    }

    // MARK: - Save

    func saveFavourite(_ movie: Movie, completion: @escaping () -> Void) {
        let context = stack.newBackgroundContext()
        context.perform {
            let request = FavouriteMovieEntity.fetchRequest()
            // Ищем, есть ли уже такой фильм
            request.predicate = NSPredicate(format: "id == %d", movie.id)

            do {
                let existing = try context.fetch(request)

                // Если фильма еще нет в базе — добавляем
                if existing.isEmpty {
                    _ = FavouriteMovieEntity.fromDomain(movie, context: context)

                    if context.hasChanges {
                        try context.save()
                    }
                }

                completion()

            } catch {
                print("Core Data save favourite failed: \(error)")
                completion()
            }
        }
    }

    // MARK: - Remove

    func removeFavourite(_ movie: Movie, completion: @escaping () -> Void) {
        let context = stack.newBackgroundContext()
        context.perform {
            let request = FavouriteMovieEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %d", movie.id)

            do {
                let existing = try context.fetch(request)

                // Если фильм есть в базе — удаляем его
                for entity in existing {
                    context.delete(entity)
                }

                if context.hasChanges {
                    try context.save()
                }

                completion()

            } catch {
                print("Core Data remove favourite failed: \(error)")
                completion()
            }
        }
    }
}
