//
//  APIError.swift
//  TheMovieDatabase
//
//  Created by Artur on 01.10.2026.
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case network(Error)
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL"
        case .noData:
            "No data received from server"
        case .decodingFailed(let error):
            "Failed to decode response: \(error.localizedDescription)"
        case .network(let error):
            "Network error: \(error.localizedDescription)"
        case .server(let statusCode):
            "Server returned status code \(statusCode)"
        }
    }
}
