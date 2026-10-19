//
//  MovieRepositoryProtocol.swift
//  TheMovieDatabase
//
//  Created by Artur on 13.10.2026.
//

import Foundation

protocol MovieRepositoryProtocol {
    
    func fetchPopular(
        page: Int,
        completion:
            @escaping (Result<PaginatedResponse<Movie>, APIError>) -> Void
    )
    
    func searchMovie(
        page: Int,
        query: String,
        completion:
            @escaping (Result<PaginatedResponse<Movie>, APIError>) -> Void
    )
}
