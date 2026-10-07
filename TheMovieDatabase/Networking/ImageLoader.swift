//
//  ImageLoader.swift
//  TheMovieDatabase
//
//  Created by Artur on 05.10.2026.
//

import UIKit

final class ImageLoader {
    static let shared = ImageLoader()
    
    // Дисковой + memrory cache HTTP-ответов (сырые Data)
    private let urlCache = URLCache(
        memoryCapacity: 20 * 1024, // 20 MB RAM
        diskCapacity: 200 * 1024 // 200 MB DISK
    )
    
    // Быстрый cache готовый UIImage
    private let imageCache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()
    
    private let session: URLSession
    
    // MARK: - Init
    
    private init () {
        let config = URLSessionConfiguration.default
        config.urlCache = urlCache
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public

    func load(url: URL, completion: @escaping (UIImage?) -> Void) {
        // 1. Готовый UIImage в памяти
        if let cached = imageCache.object(forKey: url as NSURL) {
            completion(cached)
            return
        }
        
        // 2. Диск / сеть через URLSession + URLCache
        session.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            
            self?.imageCache.setObject(image, forKey: url as NSURL, cost: data.count)
            completion(image)
        }.resume()
    }
    
    func clearCache() {
        imageCache.removeAllObjects()
        urlCache.removeAllCachedResponses()
    }
}
