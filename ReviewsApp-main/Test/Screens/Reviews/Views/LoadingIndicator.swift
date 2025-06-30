import UIKit

final class LoadingIndicator: UIView {
    
    enum Style {
        case small
        case medium
        case large

        var dotSize: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 11
            case .large: return 16
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 25
            case .large: return 30
            }
        }
    }
    
    private let style: Style
    private let dotCount = 3
    private var layers: [CALayer] = []
    
    init(style: Style = .medium) {
        self.style = style
        super.init(frame: .zero)
        isHidden = true
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        let width = CGFloat(dotCount) * style.dotSize + CGFloat(dotCount - 1) * style.spacing
        return CGSize(width: width, height: style.dotSize)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayers()
    }

}

// MARK: - Public

extension LoadingIndicator {
    
    func startAnimating() {
        isHidden = false
        for (index, dot) in layers.enumerated() {
            let animation = createAnimation(delay: Double(index) * 0.1)
            dot.add(animation, forKey: "moveAnimation")
        }
    }

    func stopAnimating() {
        isHidden = true
        layers.forEach { $0.removeAllAnimations() }
    }
    
}

// MARK: - Private

private extension LoadingIndicator {
    
    func setupLayers() {
        guard layers.isEmpty, bounds.width > 0 else { return }

        let totalWidth = CGFloat(dotCount) * style.dotSize + CGFloat(dotCount - 1) * style.spacing
        let startX = (bounds.width - totalWidth) / 2
        let centerY = bounds.height / 2

        for i in 0..<dotCount {
            let x = startX + CGFloat(i) * (style.dotSize + style.spacing)
            let dotLayer = CALayer()
            dotLayer.frame = CGRect(x: x, y: centerY - style.dotSize / 2, width: style.dotSize, height: style.dotSize)
            dotLayer.cornerRadius = style.dotSize / 2
            dotLayer.backgroundColor = UIColor.systemBlue.cgColor
            layer.addSublayer(dotLayer)
            layers.append(dotLayer)
        }
    }

    func createAnimation(delay: CFTimeInterval) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        animation.values = [0, -10, 0] 
        animation.keyTimes = [0, 0.5, 1]
        animation.duration = 0.6
        animation.beginTime = CACurrentMediaTime() + delay
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        return animation
    }
    
}
