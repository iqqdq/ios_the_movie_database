//
//  APIError.swift
//  TheMovieDatabase
//
//  Created by Artur on 01.10.2026.
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case decodingFailed(Error)
    case network(Error)
    case server(statusCode: Int)

    // MARK: - Log

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received from server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        case .server(let statusCode):
            return "Server returned status code \(statusCode)"
        }
    }

    // MARK: - UI

    var userMessage: String {
        switch self {
        case .network:
            return NSLocalizedString(
                "api_error_network",
                comment: "Error shown when network request fails"
            )
        case .server:
            return NSLocalizedString(
                "api_error_server",
                comment: "Error shown when server returns an error"
            )
        case .invalidURL, .invalidResponse, .noData, .decodingFailed:
            return NSLocalizedString(
                "api_error_generic",
                comment: "Generic error message"
            )
        }
    }
}
