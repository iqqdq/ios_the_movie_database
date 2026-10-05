//
//  ImageLoader.swift
//  TheMovieDatabase
//
//  Created by Artur on 05.10.2026.
//

import UIKit

final class ImageLoader {
    static let shared = ImageLoader()

    private init() {}

    private let cache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()

    func load(url: URL, completion: @escaping (UIImage?) -> Void) {
        if let cached = cache.object(forKey: url as NSURL) {
            completion(cached)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            
            self?.cache.setObject(image, forKey: url as NSURL)
            completion(image)
        }.resume()
    }
}
