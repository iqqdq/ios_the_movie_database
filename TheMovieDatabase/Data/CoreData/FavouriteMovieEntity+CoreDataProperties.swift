//
//  FavoriteMovieEntity+CoreDataProperties.swift
//  TheMovieDatabase
//
//  Created by Artur on 20.10.2026.
//
//

public import Foundation
public import CoreData


public typealias FavouriteMovieEntityCoreDataPropertiesSet = NSSet

extension FavouriteMovieEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FavouriteMovieEntity> {
        return NSFetchRequest<FavouriteMovieEntity>(entityName: "FavouriteMovieEntity")
    }

    @NSManaged nonisolated public var id: Int64
    @NSManaged nonisolated public var overview: String
    @NSManaged nonisolated public var posterPath: String?
    @NSManaged nonisolated public var releaseDate: String
    @NSManaged nonisolated public var title: String
    @NSManaged nonisolated public var voteAverage: Double
    @NSManaged nonisolated public var voteCount: Int64
    @NSManaged nonisolated public var addedAt: Date

}

extension FavouriteMovieEntity : Identifiable {

}
