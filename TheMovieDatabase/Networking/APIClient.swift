//
//  APIClient.swift
//  TheMovieDatabase
//
//  Created by Artur on 01.10.2026.
//

import Foundation

final class APIClient {
    static let shared = APIClient()
    private init() {}
    
    func get<T: Decodable>(
        endpoint: Endpoint,
        response: T.Type,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        var components = URLComponents(string: "\(Constants.baseURL)\(endpoint.path)")
        components?.queryItems = endpoint.queryItems + [
            URLQueryItem(name: "api_key", value: Secrets.apiKey)
        ]
        
        guard let url = components?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(APIError.network(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(APIError.server(statusCode: httpResponse.statusCode)))
                return
            }
            
            guard let data = data, !data.isEmpty else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(APIError.decodingFailed(error)))
            }
        }.resume()
    }
}
