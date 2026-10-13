//
//  MovieListState.swift
//  TheMovieDatabase
//
//  Created by Artur on 13.10.2026.
//

enum MovieListState {
    case idle
    case loading
    case loadingMore
    case refreshing
    case loaded
    case empty
    case error(String)
    case loadMoreError
}
