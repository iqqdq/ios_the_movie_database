//
//  MovieCacheStorage.swift
//  TheMovieDatabase
//
//  Created by Artur on 20.10.2026.
//

import Foundation
import CoreData

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
        // 1. Берем контекст для чтения (main)
        let context = stack.viewContext
        
        // 2. Выполняем на главном потоке, так как viewContext привязан к main
        context.perform {
            let request = MovieEntity.fetchRequest()
            
            // 3. Фильтр: только нужная страница (page == N)
            request.predicate = NSPredicate(format: "page == %d", page)
            
            // 4. Сортировка: строго по порядку (orderIndex)
            request.sortDescriptors = [
                NSSortDescriptor(key: "orderIndex", ascending: true)
            ]
            
            do {
                // 5. Получаем массив объектов MovieEntity из базы
                let entities = try context.fetch(request)
                
                // 6. Превращаем в массив чистых Movie (через маппинг)
                let movies = entities.compactMap { $0.toDomain() }
                
                // 7. Отдаем в UI (уже на main, так как perform вызывается на main)
                completion(movies)
            } catch {
                print("Core Data fetch failed: \(error)")
                completion([])
            }
        }
    }
    
    // MARK: - Save
    
    func savePopular(_ movies: [Movie], page: Int, completion: @escaping () -> Void) {
        // 1. Берем фоновый контекст (чтобы не тормозить UI)
        let context = stack.newBackgroundContext()
        
        // 2. Выполняем работу в фоне
        context.perform { [weak self] in
            guard let self else { return }
            
            // 3. Сначала УДАЛЯЕМ старые данные для этой страницы (чтобы не было дублей)
            let request = MovieEntity.fetchRequest()
            request.predicate = NSPredicate(format: "page == %d", page)
            
            do {
                let oldEntities = try context.fetch(request)
                for entity in oldEntities {
                    context.delete(entity)
                }
                
                // 4. СОЗДАЕМ новые объекты
                for (index, movie) in movies.enumerated() {
                    // Используем наш маппинг из Шага 2
                    _ = MovieEntity.fromDomain(
                        movie,
                        page: page,
                        orderIndex: index,
                        context: context
                    )
                }
                
                // 5. СОХРАНЯЕМ в базу
                if context.hasChanges {
                    try context.save()
                }
                
                // 6. Возвращаемся на главный поток и сообщаем, что всё готово
                DispatchQueue.main.async {
                    completion()
                }
            } catch {
                print("Core Data save failed: \(error)")
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    // MARK: - Clear
    
    func clear(completion: @escaping () -> Void) {
        let context = stack.newBackgroundContext()
        
        context.perform {
            let request = MovieEntity.fetchRequest()
            // Удаляем вообще всё
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
            
            do {
                try context.execute(deleteRequest)
                // ВАЖНО: после Batch Delete нужно обновить главный контекст,
                // чтобы он "узнал" об удалениях
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: []],
                    into: [self.stack.viewContext]
                )
                DispatchQueue.main.async { completion() }
            } catch {
                print("Core Data clear failed: \(error)")
                DispatchQueue.main.async { completion() }
            }
        }
    }
}
