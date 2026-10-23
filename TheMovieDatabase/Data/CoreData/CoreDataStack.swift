//
//  CoreDataStack.swift
//  TheMovieDatabase
//
//  Created by Artur on 20.10.2026.
//

import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()
    
    private let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    // MARK: - Init
    
    init() {
        container = NSPersistentContainer(name: "MovieCache")
        container.loadPersistentStores { description, error in
            if let error {
                fatalError("Core Data failed to load: \(error)")
            }
            print("Core Data loaded: \(description.url?.path ?? "")")
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Save
    
    func saveViewContext() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            print("Core Data save failed: \(error)")
        }
    }
    
    // MARK: - Background
    
    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
