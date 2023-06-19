import UIKit

final class PhotoCardView: UIView {
    
    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "posterDefault")
        iv.contentMode = .scaleToFill
        iv.layer.cornerRadius = 10
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with photo: PhotoElement) {
        guard let url = URL(string: photo.urls.thumb) else { return }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                self?.posterImageView.image = UIImage(named: "posterDefault")
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                self?.posterImageView.image = image
            }
        }
        task.resume()
    }
    
    private func setup() {
        self.backgroundColor = .lightGray
        self.setShadow()
    }
    
    func clearImage() {
        posterImageView.image = nil
    }
    
    private func setupUI() {
        addSubviews(posterImageView)
        
        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            posterImageView.rightAnchor.constraint(equalTo: rightAnchor),
            posterImageView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setShadow() {
        layer.cornerRadius = 10
        layer.masksToBounds = false
        layer.shadowOpacity = 0.83
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowColor = UIColor.black.cgColor
    }
}
