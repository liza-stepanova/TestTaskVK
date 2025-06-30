import Foundation
import UIKit
import Combine

/// Класс для загрузки фотографий.
final class PhotoProvider {

    private let session: URLSession
    private let cache = NSCache<NSString, UIImage>()

    init(session: URLSession = .shared) {
        self.session = session
    }
    
}

// MARK: - Internal

extension PhotoProvider {
    
    enum LoadImageError: Error {
        case invalidData
        case invalidURL
        case network(Error)
    }
    
    func publisher(for urlString: String) -> AnyPublisher<UIImage, LoadImageError> {
        guard let url = URL(string: urlString) else {
            return Fail(error: LoadImageError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        if let cached = cache.object(forKey: url.absoluteString as NSString) {
            return Just(cached)
                .setFailureType(to: LoadImageError.self)
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .tryMap { [weak self] data, _ -> UIImage in
                guard let img = UIImage(data: data) else {
                    throw LoadImageError.invalidData
                }
                self?.cache.setObject(img, forKey: url.absoluteString as NSString)
                return img
            }
            .mapError { ($0 as? LoadImageError) ?? .network($0) }
            .eraseToAnyPublisher()
    }
    
}
