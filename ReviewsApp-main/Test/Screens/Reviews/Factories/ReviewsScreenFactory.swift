final class ReviewsScreenFactory {

    /// Создаёт контроллер списка отзывов, проставляя нужные зависимости.
    static func makeReviewsController() -> ReviewsViewController {
        let reviewsProvider = ReviewsProvider()
        let viewModel = ReviewsViewModel(reviewsProvider: reviewsProvider)
        let controller = ReviewsViewController(viewModel: viewModel)
        return controller
    }

}
