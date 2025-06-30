import UIKit

class PhotoContentViewController: UIViewController {
    
    private lazy var photoContentView = PhotoContentView()
    let image: UIImage
    
    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = photoContentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPhotoContentView()
    }
    
}

// MARK: - Private

private extension PhotoContentViewController {
    
    func setupPhotoContentView() {
        photoContentView.image = image
    }
    
}
