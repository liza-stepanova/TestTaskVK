import UIKit
import Combine

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject, ReviewsViewModelProtocol {

    var onOpenGallery: ((Int, [UIImage]) -> Void)?
    var onScrollToTopVisibilityChange: ((Bool) -> Void)?

    var updates: AnyPublisher<ReviewsUpdate, Never> {
        updatesSubject.eraseToAnyPublisher()
    }
    private let updatesSubject = PassthroughSubject<ReviewsUpdate, Never>()
    private var imageCancellablesById: [UUID: Set<AnyCancellable>] = [:]
    
    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let photoProvider: PhotoProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder

    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        photoProvider: PhotoProvider = PhotoProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.photoProvider = photoProvider
        self.ratingRenderer = ratingRenderer
        self.decoder = decoder
    }

}

// MARK: - Internal

extension ReviewsViewModel {

    typealias State = ReviewsViewModelState

    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        
        if state.offset == .zero && state.items.isEmpty {
            updatesSubject.send(.loadingStarted)
        }
        
        self.reviewsProvider.getReviews(offset: self.state.offset) { [weak self] result in
            guard let self else { return }
            self.gotReviews(result)
        }
    }
    
    /// Метод обновления отзывов.
    func refreshReviews() {
        state.items.removeAll()
        state.offset = 0
        state.shouldLoad = true
        imageCancellablesById.removeAll()
        updatesSubject.send(.fullReload)
        getReviews()
    }
    
}

// MARK: - Network

private extension ReviewsViewModel {

    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        do {
            let data = try result.get()
            let reviews = try self.decoder.decode(Reviews.self, from: data)
            let newItems = reviews.items.map(self.makeReviewItem)
                
            DispatchQueue.main.async {
                self.state.items.removeAll { $0 is ReviewCountItem }
                let start = self.state.items.count
                self.state.items += newItems
                self.state.offset += self.state.limit
                self.state.shouldLoad = self.state.offset < reviews.count
                    
                let end = start + newItems.count
                var indexPaths = (start..<end).map {
                    IndexPath(row: $0, section: 0)
                }
                if !self.state.shouldLoad {
                    let countItem = self.makeReviewCountItem(
                        self.state.items.count
                    )
                    self.state.items.append(countItem)
                    indexPaths.append(IndexPath(row: self.state.items.count - 1, section: 0))
                }
                    
                self.startImageLoading(
                    for: reviews.items,
                    startingFromRow: start
                )
                if start == 0 {
                    self.updatesSubject.send(.fullReload)
                } else {
                    self.updatesSubject.send(.insertRows(indexPaths))
                }
                self.updatesSubject.send(.loadingFinished)
            }
        } catch {
            DispatchQueue.main.async {
                self.state.shouldLoad = true
                self.updatesSubject.send(.showError("Нет доступа к сети."))
            }
        }
    }
    
    private func startImageLoading(for reviews: [Review], startingFromRow start: Int) {
        for (offset, review) in reviews.enumerated() {
            let row = start + offset
            guard let item = state.items[row] as? ReviewItem else { continue }
            let id = item.id
            
            imageCancellablesById[id] = []
            
            if let url = review.avatarUrl {
                photoProvider.publisher(for: url)
                    .receive(on: DispatchQueue.main)
                    .sink (
                        receiveCompletion: { _ in },
                        receiveValue: { [weak self] img in
                        self?.applyAvatar(img, toItemWith: id)
                    })
                    .store(in: &imageCancellablesById[id, default: []])
            }

            if let urls = review.photoUrls?.prefix(Constants.maxReviewPhotosCount) {
                urls.enumerated().forEach { index, url in
                    photoProvider.publisher(for: url)
                        .receive(on: DispatchQueue.main)
                        .sink (
                            receiveCompletion: { [weak self] completion in
                                if case .failure = completion {
                                    self?.applyPhoto(
                                        UIImage.placeholderError,
                                        at: index,
                                        toItemWith: id,
                                        totalCount: urls.count
                                    )
                                }
                            },
                            receiveValue: { [weak self] img in
                            self?.applyPhoto(img, at: index, toItemWith: id, totalCount: urls.count)
                        })
                        .store(in: &imageCancellablesById[id, default: []])
                }
            }
        }
    }

}

// MARK: - Items

private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig
    typealias ReviewCountItem = ReviewCountCellConfig

    func makeReviewItem(_ review: Review) -> ReviewItem {
        let avatarImage = UIImage.avatar
        let firstNameText = review.firstName.attributed(font: .username)
        let lastNameText = review.lastName.attributed(font: .username)
        let rating = review.rating
        var photos: [UIImage]? = nil
        if let urls = review.photoUrls {
            photos = Array(repeating: UIImage.placeholderLoading, count: urls.count)
        }
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        let item = ReviewItem(
            avatarImage: avatarImage,
            firstNameText: firstNameText,
            lastNameText: lastNameText,
            rating: rating,
            photos: photos,
            reviewText: reviewText,
            created: created,
            onTapShowMore: { [weak self] id in
                self?.showMoreReview(with: id)
            },
            onPhotoTap: { [weak self] index, images in
                guard let self = self else { return }
                self.onOpenGallery?(index, images)
            }
        )
        
        return item
    }
    
    func makeReviewCountItem(_ count: Int) -> ReviewCountItem {
        let countText = String(count)
        let reviewText = localizedReviewWord(for: count)
        let reviewCountText = countText + " " + reviewText
        let text = reviewCountText.attributed(
            font: .reviewCount,
            color: .reviewCount
        )
            
        return ReviewCountItem(reviewCountText: text)
    }
        
    func localizedReviewWord(for count: Int) -> String {
        let lastNumber = count % 10
        switch lastNumber {
        case 1:
            return "отзыв"
        case 2...4:
            return "отзыва"
        default:
            return "отзывов"
        }
    }

}

// MARK: - State

private extension ReviewsViewModel {
    
    func applyAvatar(_ image: UIImage, toItemWith id: UUID) {
        guard let row = state.items.firstIndex(
            where: { ($0 as? ReviewItem)?.id == id
            }),
              var item = state.items[row] as? ReviewItem
        else { return }
        item.avatarImage = image
        state.items[row] = item
        updatesSubject.send(.reloadRows([IndexPath(row: row, section: 0)]))
    }
    
    func applyPhoto(_ image: UIImage, at index: Int, toItemWith id: UUID, totalCount: Int) {
        guard let row = state.items.firstIndex(
            where: { ($0 as? ReviewItem)?.id == id
            }),
              var item = state.items[row] as? ReviewItem
        else { return }
        
        if item.photos == nil {
            item.photos = Array(repeating: UIImage(), count: totalCount)
        }
        
        item.photos?[index] = image
        state.items[row] = item
        updatesSubject.send(.reloadRows([IndexPath(row: row, section: 0)]))
    }
    
    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        
        updatesSubject.send(.reloadRows([IndexPath(row: index, section: 0)]))
    }
    
}

// MARK: - Constants
private extension ReviewsViewModel {
    
    enum Constants {
        static let scrollToTopVisibilityThreshold: CGFloat = 300
        static let screensToLoadNextPage: CGFloat = 2.5
        static let maxReviewPhotosCount = 5
    }
    
}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config = state.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: config.reuseId,
            for: indexPath
        )
        config.update(cell: cell)
        return cell
    }
    
}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        state.items[indexPath.row].height(with: tableView.bounds.size)
    }

    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let shouldShow = scrollView.contentOffset.y > Constants.scrollToTopVisibilityThreshold
        onScrollToTopVisibilityChange?(shouldShow)
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * Constants.screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }

}
