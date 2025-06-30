import UIKit

struct ReviewCountCellConfig {
    
    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: ReviewCountCellConfig.self)
    /// Количество отзывов.
    let reviewCountText: NSAttributedString
    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = ReviewCountCellLayout()
}

// MARK: - TableCellConfig

extension ReviewCountCellConfig: TableCellConfig {
    
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCountCell else { return }
        cell.reviewCountLabel.attributedText = reviewCountText
        cell.config = self
    }
    
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }
    
}

// MARK: - Cell

final class ReviewCountCell: UITableViewCell {
    
    fileprivate var config: Config?
    
    fileprivate let reviewCountLabel = UILabel()
    
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
        reviewCountLabel.frame = layout.reviewCountLabelFrame
    }
    
}

// MARK: - Private

private extension ReviewCountCell {
    
    func setupCell() {
        setupReviewCountLabel()
    }
    
    func setupReviewCountLabel() {
        contentView.addSubview(reviewCountLabel)
        reviewCountLabel.lineBreakMode = .byWordWrapping
    }
    
}

// MARK: - Layout

private final class ReviewCountCellLayout {
    
    private(set) var reviewCountLabelFrame = CGRect.zero
    
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)
    
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        let width = maxWidth - insets.left - insets.right
        let textSize = config.reviewCountText.boundingRect(width: width).size
        let x = insets.left + (width - textSize.width) / 2
        let maxY = insets.top
        
        reviewCountLabelFrame = CGRect(
            origin: CGPoint(x: x, y: maxY),
            size: textSize
        )

        return reviewCountLabelFrame.maxY + insets.bottom
    }
    
}

// MARK: - Typealias

fileprivate typealias Config = ReviewCountCellConfig
fileprivate typealias Layout = ReviewCountCellLayout
