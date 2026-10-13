//
//  PaginatedResponse.swift
//  TheMovieDatabase
//
//  Created by Artur on 01.10.2026.
//


import Foundation

struct PaginatedResponse<T: Decodable>: Decodable {
    let page: Int
    let results: [T]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
