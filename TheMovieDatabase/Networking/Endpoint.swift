//
//  Endpoint.swift
//  TheMovieDatabase
//
//  Created by Artur on 01.10.2026.
//

import Foundation

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]

    init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = []
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
