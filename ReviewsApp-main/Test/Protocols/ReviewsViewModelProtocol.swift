import Foundation
import UIKit
import Combine

protocol ReviewsViewModelProtocol: AnyObject, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    var updates: AnyPublisher<ReviewsUpdate, Never> { get }
    var onOpenGallery: ((Int, [UIImage]) -> Void)? { get set }
    var onScrollToTopVisibilityChange: ((Bool) -> Void)? { get set }
    
    // MARK: - Methods
    func getReviews()
    func refreshReviews()
    
}
