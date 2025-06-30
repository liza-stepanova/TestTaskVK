import UIKit
import Combine

final class ReviewsViewController: UIViewController {

    private lazy var reviewsView = makeReviewsView()
    private lazy var scrollToTopButton = makeScrollToTopButton()
    private lazy var errorLabel = makeErrorLabel()
    
    private let viewModel: ReviewsViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    private let refreshControl = UIRefreshControl()

    init(viewModel: ReviewsViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = reviewsView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Отзывы"
        
        setupRefreshControl()
        setupScrollToTopButton()
        setupErrorLabel()
        bindViewModel()
        viewModel.getReviews()
    }
    
}

// MARK: - Private

private extension ReviewsViewController {

    func bindViewModel() {
        viewModel.onScrollToTopVisibilityChange = { [weak self] isVisible in
            self?.scrollToTopButton.isHidden = !isVisible
        }

        viewModel.onOpenGallery = { [weak self] selectedIndex, images in
            self?.presentGallery(images, startingAt: selectedIndex)
        }
        
        viewModel.updates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self = self else { return }
                
                switch update {
                case .insertRows(let paths):
                    self.reviewsView.tableView.insertRows(at: paths, with: .fade)
                    
                case .reloadRows(let paths):
                    self.reviewsView.tableView.reloadRows(at: paths, with: .none)
                    
                case .fullReload:
                    self.reviewsView.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                    self.errorLabel.isHidden = true
                    
                case .loadingStarted:
                    self.reviewsView.activityIndicator.startAnimating()
                    self.errorLabel.isHidden = true
                    self.reviewsView.tableView.isHidden = true
                    
                case .loadingFinished:
                    self.reviewsView.activityIndicator.stopAnimating()
                    self.reviewsView.tableView.isHidden = false
                    
                case .showError(let error):
                    self.showError(error)
                }
                
            }.store(in: &cancellables)
    }
    
    func presentGallery(_ images: [UIImage], startingAt index: Int) {
        let vc = PhotoPageViewController(images: images, startIndex: index)
        vc.modalPresentationStyle = .fullScreen
        
        present(vc, animated: true)
    }
    
    func showError(_ message: String) {
        errorLabel.isHidden = false
        errorLabel.text = message
        reviewsView.activityIndicator.stopAnimating()
        reviewsView.tableView.isHidden = true
    }

    func setupErrorLabel() {
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        reviewsView.addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            errorLabel.leadingAnchor.constraint(equalTo: reviewsView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: reviewsView.trailingAnchor, constant: -20),
            errorLabel.centerYAnchor.constraint(equalTo: reviewsView.centerYAnchor)
        ])
    }
    
    func setupScrollToTopButton() {
        view.addSubview(scrollToTopButton)
        scrollToTopButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollToTopButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollToTopButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            scrollToTopButton.widthAnchor.constraint(equalToConstant: 50),
            scrollToTopButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshReviews), for: .valueChanged)
        reviewsView.tableView.refreshControl = refreshControl
    }
        
    @objc func refreshReviews() {
        viewModel.refreshReviews()
    }
    
    @objc func scrollToTop() {
        let table = reviewsView.tableView
        guard table.numberOfSections > 0, table.numberOfRows(inSection: 0) > 0 else { return }
        let top = IndexPath(row: 0, section: 0)
        table.scrollToRow(at: top, at: .top, animated: true)
    }

}

// MARK: Fabric

private extension ReviewsViewController {
    
    func makeReviewsView() -> ReviewsView {
        let reviewsView = ReviewsView()
        reviewsView.tableView.delegate = viewModel
        reviewsView.tableView.dataSource = viewModel
        return reviewsView
    }
    
    func makeScrollToTopButton() -> UIButton {
        let button = UIButton()
        button.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 25
        button.isHidden = true
        button.addTarget(self, action: #selector(scrollToTop), for: .touchUpInside)
        return button
    }
    
    func makeErrorLabel() -> UILabel {
        let label = UILabel()
        label.textColor = .gray
        label.textAlignment = .center
        label.font = .error
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }
    
}
