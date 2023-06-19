import UIKit

class FavoritesCell: UITableViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.italicSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleToFill
        iv.layer.cornerRadius = 10
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let margins = UIEdgeInsets(top: 11, left: 22, bottom: 11, right: 18)
        contentView.frame = contentView.frame.inset(by: margins)
        contentView.layer.cornerRadius = 8
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        selectionStyle = .none
    }
    
    private func setupUI() {
        
        contentView.addSubviews(posterImageView, titleLabel)
        
        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterImageView.widthAnchor.constraint(equalToConstant: 100),
            posterImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: posterImageView.topAnchor, constant: 20),
            titleLabel.leftAnchor.constraint(equalTo: posterImageView.rightAnchor, constant: 10),
            titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10),
        ])
    }
    
    func setup(_ photoElement: PhotoElement?) {
        guard let photoElement = photoElement else { return }
        fetchImage(with: photoElement)
        titleLabel.text = photoElement.user.name
    }
    
    private func fetchImage(with photo: PhotoElement) {
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
}
