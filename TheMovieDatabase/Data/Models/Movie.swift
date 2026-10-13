//
//  Movie.swift
//  TheMovieDatabase
//
//  Created by Artur on 01.10.2026.
//


import Foundation

struct Movie: Decodable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let releaseDate: String
    let voteAverage: Double
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}

extension Movie {
    var posterURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: Constants.imageBaseURL + posterPath)
    }
}
