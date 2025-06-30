import UIKit

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct ReviewCellConfig {

    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: ReviewCellConfig.self)
    /// Используется для генерации изображения рейтинга (звёзды).
    private static let ratingRenderer = RatingRenderer()
    /// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
    let id = UUID()
    /// Аватар пользователя.
    var avatarImage: UIImage?
    /// Имя и фамилия пользователя.
    let firstNameText: NSAttributedString
    let lastNameText: NSAttributedString
    /// Рейтинг отзыва.
    let rating: Int
    /// Фотографии отзыва.
    var photos: [UIImage]?
    /// Текст отзыва.
    let reviewText: NSAttributedString
    /// Максимальное отображаемое количество строк текста. По умолчанию 3.
    var maxLines = 3
    /// Время создания отзыва.
    let created: NSAttributedString
    /// Замыкание, вызываемое при нажатии на кнопку "Показать полностью...".
    let onTapShowMore: (UUID) -> Void
    /// Замыкание, вызываемое при нажатии на фотографию
    var onPhotoTap: (Int, [UIImage]) -> Void

    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = ReviewCellLayout()

}

// MARK: - TableCellConfig

extension ReviewCellConfig: TableCellConfig {

    /// Метод обновления ячейки.
    /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCell else { return }
        
        cell.avatarImageView.image = avatarImage
        cell.reviewTextLabel.attributedText = reviewText
        cell.reviewTextLabel.numberOfLines = maxLines
        cell.ratingImageView.image = Self.ratingRenderer.ratingImage(rating)
        updatePhotos(in: cell)
        cell.createdLabel.attributedText = created
        cell.usernameLabel.attributedText = fullName
        cell.config = self
    }

    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }

}

// MARK: - Private

private extension ReviewCellConfig {
    
    var fullName: NSAttributedString {
        let separator = NSAttributedString(string: " ")
        let fullName = NSMutableAttributedString()
        fullName.append(firstNameText)
        fullName.append(separator)
        fullName.append(lastNameText)
        
        return fullName
    }

    /// Текст кнопки "Показать полностью...".
    static let showMoreText = "Показать полностью..."
        .attributed(font: .showMore, color: .showMore)
    
    func updatePhotos(in cell: ReviewCell) {
        for (index, imageView) in cell.photoImageViews.enumerated() {
            let indicator = cell.photoLoadingIndicators[index]
            imageView.image = nil
            imageView.isHidden = true
            indicator.stopAnimating()
            indicator.isHidden = true
        }

        guard let photos = photos else { return }

        for (index, image) in photos.prefix(cell.photoImageViews.count).enumerated() {
            let imageView = cell.photoImageViews[index]
            let indicator = cell.photoLoadingIndicators[index]
            
            imageView.image = image
            imageView.isHidden = false
            if image == UIImage.placeholderLoading {
                indicator.isHidden = false
                indicator.startAnimating()
            } else {
                indicator.isHidden = true
                indicator.stopAnimating()
            }
        }
    }

}

// MARK: - Cell

final class ReviewCell: UITableViewCell {

    fileprivate var config: Config?
    
    fileprivate let avatarImageView = UIImageView()
    fileprivate let usernameLabel = UILabel()
    fileprivate var ratingImageView = UIImageView()
    fileprivate let reviewTextLabel = UILabel()
    fileprivate let createdLabel = UILabel()
    fileprivate var photoImageViews: [UIImageView] = []
    fileprivate var photoLoadingIndicators: [UIActivityIndicatorView] = []
    fileprivate let showMoreButton = UIButton()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }
        
        avatarImageView.frame = layout.avatarImageFrame
        usernameLabel.frame = layout.usernameLabelFrame
        ratingImageView.frame = layout.ratingImageFrame
        if !photoImageViews.isEmpty {
            for (index, item) in layout.photoFrames.enumerated() {
                photoImageViews[index].frame = item
                let indicator = photoLoadingIndicators[index]
                indicator.frame = item
                indicator.center = CGPoint(x: item.midX, y: item.midY)
            }
        }
        reviewTextLabel.frame = layout.reviewTextLabelFrame
        createdLabel.frame = layout.createdLabelFrame
        showMoreButton.frame = layout.showMoreButtonFrame
    }

}

// MARK: - Private

private extension ReviewCell {

    func setupCell() {
        setupAvatarImage()
        setupShowMoreButton()
        setupPhotoImageViews()
        setupLabels()
        addSubviews()
        addGestures()
    }
    
    func setupAvatarImage() {
        avatarImageView.tag = Constants.avatarTag
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = Layout.avatarCornerRadius
    }
    
    func setupLabels() {
        usernameLabel.lineBreakMode = .byWordWrapping
        reviewTextLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupPhotoImageViews() {
        for index in 0..<Constants.maxPhotoCount {
            let imageView = UIImageView()
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = Layout.photoCornerRadius
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = true
            imageView.tag = index
            
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.hidesWhenStopped = true
            
            photoLoadingIndicators.append(activityIndicator)
            photoImageViews.append(imageView)
        }
    }
    
    func addSubviews() {
        [avatarImageView,
         usernameLabel,
         reviewTextLabel,
         ratingImageView,
         createdLabel,
         showMoreButton
        ].forEach { contentView.addSubview($0) }

        photoImageViews.forEach { contentView.addSubview($0) }
        photoLoadingIndicators.forEach { contentView.addSubview($0) }
    }

    func setupShowMoreButton() {
        showMoreButton.contentVerticalAlignment = .fill
        showMoreButton.setAttributedTitle(Config.showMoreText, for: .normal)
        showMoreButton.addTarget(self, action: #selector(didTapShowMore), for: .touchUpInside)
    }
    
    func addGestures() {
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(photoTapped(_:)))
        )
        photoImageViews.forEach { imageView in
            imageView.addGestureRecognizer(UITapGestureRecognizer(
                target: self,
                action: #selector(photoTapped(_:)))
            )
        }
    }
    
    @objc func didTapShowMore() {
        guard let config else { return }
        config.onTapShowMore(config.id)
    }
    
    @objc func photoTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedView = sender.view as? UIImageView, let config else { return }
        let index = tappedView.tag

        if index == Constants.avatarTag {
            guard let avatar = avatarImageView.image else { return }
            config.onPhotoTap(0, [avatar])
        } else if index >= 0, index < (config.photos?.count ?? 0) {
            guard let photos = config.photos else { return }
            config.onPhotoTap(index, photos)
        }
    }

}

// MARK: - Constants

private extension ReviewCell {
    
    enum Constants {
        static let maxPhotoCount = 5
        static let avatarTag = -1
    }
    
}

// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
/// После расчётов возвращается актуальная высота ячейки.
private final class ReviewCellLayout {

    // MARK: - Размеры

    fileprivate static let avatarSize = CGSize(width: 36.0, height: 36.0)
    fileprivate static let avatarCornerRadius = 18.0
    fileprivate static let photoCornerRadius = 8.0

    private static let photoSize = CGSize(width: 55.0, height: 66.0)
    private static let showMoreButtonSize = Config.showMoreText.size()
    
    private static let ratingImageSize = CGSize(width: 84, height: 16)

    // MARK: - Фреймы

    private(set) var avatarImageFrame = CGRect.zero
    private(set) var usernameLabelFrame = CGRect.zero
    private(set) var ratingImageFrame = CGRect.zero
    private(set) var photoFrames: [CGRect] = Array(repeating: .zero, count: 5)
    private(set) var reviewTextLabelFrame = CGRect.zero
    private(set) var showMoreButtonFrame = CGRect.zero
    private(set) var createdLabelFrame = CGRect.zero

    // MARK: - Отступы

    /// Отступы от краёв ячейки до её содержимого.
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)

    /// Горизонтальный отступ от аватара до имени пользователя.
    private let avatarToUsernameSpacing = 10.0
    /// Вертикальный отступ от имени пользователя до вью рейтинга.
    private let usernameToRatingSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до текста (если нет фото).
    private let ratingToTextSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до фото.
    private let ratingToPhotosSpacing = 10.0
    /// Горизонтальные отступы между фото.
    private let photosSpacing = 8.0
    /// Вертикальный отступ от фото (если они есть) до текста отзыва.
    private let photosToTextSpacing = 10.0
    /// Вертикальный отступ от текста отзыва до времени создания отзыва или кнопки "Показать полностью..." (если она есть).
    private let reviewTextToCreatedSpacing = 6.0
    /// Вертикальный отступ от кнопки "Показать полностью..." до времени создания отзыва.
    private let showMoreToCreatedSpacing = 6.0

    // MARK: - Расчёт фреймов и высоты ячейки

    /// Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        let leftInsetWithAvatar = insets.left + avatarToUsernameSpacing + ReviewCellLayout.avatarSize.width
        let width = maxWidth - leftInsetWithAvatar - insets.right

        var maxY = insets.top
        var showShowMoreButton = false
        
        avatarImageFrame = CGRect(
            origin: CGPoint(x: insets.left, y: maxY),
            size: ReviewCellLayout.avatarSize
        )
                
        usernameLabelFrame = CGRect(
            origin: CGPoint(x: leftInsetWithAvatar, y: maxY),
            size: config.fullName.boundingRect(width: width).size
        )
        maxY = usernameLabelFrame.maxY + usernameToRatingSpacing

        ratingImageFrame = CGRect(
            origin: CGPoint(x: leftInsetWithAvatar, y: maxY),
            size: Layout.ratingImageSize
        )
        maxY = ratingImageFrame.maxY + ratingToTextSpacing

        if let photos = config.photos, !photos.isEmpty {
            maxY = ratingImageFrame.maxY + ratingToPhotosSpacing
                    
            photoFrames = self.calculatePhotosFrames(
                config: config,
                leftInset: leftInsetWithAvatar,
                photosSpacing: photosSpacing,
                maxY: maxY
            )
            maxY = photoFrames[0].maxY + photosToTextSpacing
        }
        
        if !config.reviewText.isEmpty() {
            // Высота текста с текущим ограничением по количеству строк.
            let currentTextHeight = (config.reviewText.font()?.lineHeight ?? .zero) * CGFloat(config.maxLines)
            // Максимально возможная высота текста, если бы ограничения не было.
            let actualTextHeight = config.reviewText.boundingRect(width: width).size.height
            // Показываем кнопку "Показать полностью...", если максимально возможная высота текста больше текущей.
            showShowMoreButton = config.maxLines != .zero && actualTextHeight > currentTextHeight

            reviewTextLabelFrame = CGRect(
                origin: CGPoint(x: leftInsetWithAvatar, y: maxY),
                size: config.reviewText.boundingRect(width: width, height: currentTextHeight).size
            )
            maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
        }

        if showShowMoreButton {
            showMoreButtonFrame = CGRect(
                origin: CGPoint(x: leftInsetWithAvatar, y: maxY),
                size: Self.showMoreButtonSize
            )
            maxY = showMoreButtonFrame.maxY + showMoreToCreatedSpacing
        } else {
            showMoreButtonFrame = .zero
        }

        createdLabelFrame = CGRect(
            origin: CGPoint(x: leftInsetWithAvatar, y: maxY),
            size: config.created.boundingRect(width: width).size
        )

        return createdLabelFrame.maxY + insets.bottom
    }
    
    /// Возвращает фреймы для каждого элемента photoImageViews
    private func calculatePhotosFrames(config: Config, leftInset: CGFloat, photosSpacing: CGFloat, maxY: CGFloat) -> [CGRect] {
        guard let photos = config.photos else { return [] }
        var frames = [CGRect]()
        var x = leftInset
            
        for (index, _) in photos.enumerated() {
            if index > 0 {
                x += ReviewCellLayout.photoSize.width + photosSpacing
            }
            let frame = CGRect(
                origin: CGPoint(x: x, y: maxY),
                size: ReviewCellLayout.photoSize
            )
            frames.append(frame)
        }
        return frames
    }

}

// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias Layout = ReviewCellLayout
