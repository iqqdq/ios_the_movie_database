//
//  SearchState.swift
//  TheMovieDatabase
//
//  Created by Artur on 14.10.2026.
//

enum SearchState {
    case idle
    case searching
    case results
    case empty
    case error(String)
    case loadingMore
    case loadMoreError
}
