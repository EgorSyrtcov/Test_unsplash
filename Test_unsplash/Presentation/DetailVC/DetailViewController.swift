import UIKit
import Combine

final class DetailViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let containerView: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    
    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "posterDefault")
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 10
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let separatorView: UIView = {
        let separatorView = UIView()
        separatorView.backgroundColor = .gray
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        return separatorView
    }()
    
    private let nameAuthLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .red
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let createDateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont(name: "Montserrat-Regular", size: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = .lightGray
        label.numberOfLines = 0
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let likesLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        label.font = UIFont(name: "Montserrat-Regular", size: 10)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy private var likeButton: UIButton = {
        let button = UIButton()
        button.setTitle("Add to Favorites", for: .normal)
        button.layer.cornerRadius = 5
        button.backgroundColor = .red
        button.addTarget(self, action: #selector(didTapButtonAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var cancellables: Set<AnyCancellable> = []
    private var photoElement: PhotoElement?
    
    // MARK: Public
    var viewModel: DetailViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupUI()
        viewModelBinding()
    }
    
    private func setup() {
        title = "Detail"
        view.backgroundColor = .white
    }
    
    private func viewModelBinding() {
        viewModel.photoDataPublisher
            .sink { [weak self] photo in
                guard let self = self else { return }
                self.photoElement = photo
                self.settingsModel()
            }
            .store(in: &cancellables)
        
        viewModel.showAlertSaveStorageBasePublisher
            .sink { [weak self] title, message in
                self?.showAlert(title: title ?? "", message: message ?? "")
            }
            .store(in: &cancellables)
        
    }
    
    private func settingsModel() {
        guard let photoElement = photoElement else { return }
        fetchImage(with: photoElement)
        nameAuthLabel.text = photoElement.user.name
        createDateLabel.text = "Created: \(photoElement.dataToString)"
        locationLabel.text = photoElement.user.location
        likesLabel.text = "Likes: \(photoElement.likes)"
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
    
    private func setupUI() {
        
        let containerSize = containerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        scrollView.contentSize = containerSize
        
        view.addSubview(scrollView)
        scrollView.addSubviews(containerView)
        containerView.addSubviews(posterImageView, nameAuthLabel, createDateLabel, locationLabel, separatorView, likesLabel, likeButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            posterImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            posterImageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            posterImageView.rightAnchor.constraint(equalTo: view.rightAnchor),
            posterImageView.heightAnchor.constraint(equalToConstant: 400),
            
            nameAuthLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 20),
            nameAuthLabel.rightAnchor.constraint(equalTo: posterImageView.rightAnchor, constant: -10),
            nameAuthLabel.leftAnchor.constraint(equalTo: posterImageView.leftAnchor, constant: 10),
            
            createDateLabel.topAnchor.constraint(equalTo: nameAuthLabel.bottomAnchor, constant: 10),
            createDateLabel.rightAnchor.constraint(equalTo: nameAuthLabel.rightAnchor, constant: -10),
            createDateLabel.leftAnchor.constraint(equalTo: nameAuthLabel.leftAnchor, constant: 10),
            
            locationLabel.topAnchor.constraint(equalTo: createDateLabel.bottomAnchor, constant: 10),
            locationLabel.rightAnchor.constraint(equalTo: posterImageView.rightAnchor, constant: -20),
            locationLabel.leftAnchor.constraint(equalTo: posterImageView.leftAnchor, constant: 20),
            
            separatorView.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 10),
            separatorView.rightAnchor.constraint(equalTo: locationLabel.rightAnchor, constant: -20),
            separatorView.leftAnchor.constraint(equalTo: locationLabel.leftAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            
            likesLabel.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 10),
            likesLabel.leftAnchor.constraint(equalTo: separatorView.leftAnchor),
            likesLabel.rightAnchor.constraint(equalTo: separatorView.rightAnchor),
            
            likeButton.topAnchor.constraint(equalTo: likesLabel.bottomAnchor, constant: 10),
            likeButton.rightAnchor.constraint(equalTo: posterImageView.rightAnchor, constant: -20),
            likeButton.leftAnchor.constraint(equalTo: posterImageView.leftAnchor, constant: 20),
            likeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: Actions
    @objc func didTapButtonAction(sender: UIButton!) {
        viewModel.didTapLikeSubject.send()
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
