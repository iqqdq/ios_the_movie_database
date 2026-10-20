//
//  MovieEntity+Mapping.swift.swift
//  TheMovieDatabase
//
//  Created by Artur on 20.10.2026.
//

import CoreData
import Foundation

extension MovieEntity {
    func toDomain() -> Movie? {
        return Movie(
            id: Int(id),
            title: title,
            overview: overview,
            posterPath: posterPath,
            releaseDate: releaseDate,
            voteAverage: voteAverage,
            voteCount: Int(voteCount)
        )
    }

    static func fromDomain(
        _ movie: Movie,
        page: Int,
        orderIndex: Int,
        context: NSManagedObjectContext
    ) -> MovieEntity {
        let entity = MovieEntity(context: context)
        entity.id = Int64(movie.id)
        entity.title = movie.title
        entity.overview = movie.overview
        entity.posterPath = movie.posterPath
        entity.releaseDate = movie.releaseDate
        entity.voteAverage = movie.voteAverage
        entity.voteCount = Int64(movie.voteCount)
        entity.page = Int64(page)
        entity.orderIndex = Int64(orderIndex)
        
        return entity
    }
}
