import UIKit
import Combine

final class MainViewController: UIViewController {
    
    lazy private var activityIndicator: UIActivityIndicatorView = {
        var activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    lazy private var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 15, left: 20, bottom: 20, right: 20)
        layout.itemSize = CGSize(width: self.view.frame.width - 80, height: 400)
        layout.minimumLineSpacing = 30
        layout.scrollDirection = .vertical
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.register(PhotoViewCell<PhotoCardView>.self)
        collection.showsVerticalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.alwaysBounceVertical = true
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()
    
    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "Search"
        navigationItem.searchController = sc
        definesPresentationContext = true
        sc.searchBar.delegate = self
        return sc
    }()
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    // MARK: Public
    var viewModel: MainViewModel!
    
    // MARK: Private
    private var photoElements = [PhotoElement]()
    private var photoSearchElements = [PhotoElement]()
    private var isLoadingMore = false
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupNavigationBarButton()
        setupUI()
        viewModelBinding()
    }
    
    private func setup() {
        title = "Photos"
        view.backgroundColor = .white
    }
    
    private func setupNavigationBarButton() {
        navigationItem.searchController = searchController
    }
    
    private func viewModelBinding() {
        
        viewModel.isLoadingPublisher
            .sink { [weak self] in self?.update(isShown: $0) }
            .store(in: &cancellables)
        
        viewModel.updatePhotoPublisher
            .sink { [weak self] returnValue in
                guard let self = self else { return }
                let currentCount = self.photoElements.count
                let newIndexPaths = (currentCount..<currentCount+returnValue.count).map { IndexPath(item: $0, section: 0) }
                self.photoElements.insert(contentsOf: returnValue, at: currentCount)
                self.isLoadingMore = false
                DispatchQueue.main.async {
                    self.collectionView.performBatchUpdates({
                        self.collectionView.insertItems(at: newIndexPaths)
                    }, completion: nil)
                }
            }
            .store(in: &cancellables)
        
        viewModel.updatePhotoSearchPublisher
            .sink { [weak self] returnValue in
                guard let self = self else { return }
                self.photoSearchElements = returnValue
                self.collectionView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.errorPublisher
            .sink { [weak self] error in
                guard let self = self else { return }
                self.showAlert(title: error.title, subtitle: error.subtitle) }
            .store(in: &cancellables)
    }
    
    private func setupUI() {
        view.addSubviews(collectionView, activityIndicator)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            activityIndicator.widthAnchor.constraint(equalToConstant: 50),
            activityIndicator.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
}

extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearchBarEmpty ? photoElements.count : photoSearchElements.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch isSearchBarEmpty {
        case true:
            let cell = collectionView.dequeueCell(cellType: PhotoViewCell<PhotoCardView>.self, for: indexPath)
            let model = photoElements[indexPath.item]
            cell.containerView.update(with: model)
            return cell
        case false:
            let cell = collectionView.dequeueCell(cellType: PhotoViewCell<PhotoCardView>.self, for: indexPath)
            let model = photoSearchElements[indexPath.item]
            cell.containerView.update(with: model)
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.size.width, height: 30.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch isSearchBarEmpty {
        case true:
            let photo = photoElements[indexPath.item]
            viewModel.detailCellDidTapSubject.send(photo)
        case false:
            let photo = photoSearchElements[indexPath.item]
            viewModel.detailCellDidTapSubject.send(photo)
        }
    }
}

extension MainViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard !searchController.isActive else { return }
        guard !isLoadingMore else { return }
        
        let offset = scrollView.contentOffset.y
        let totalContentHeight = scrollView.contentSize.height
        let totalScrollViewFixedHeight = scrollView.frame.size.height
        
        if offset > (totalContentHeight - totalScrollViewFixedHeight) {
            isLoadingMore = true
            viewModel.scrollLoadingMoreSubject.send()
        }
    }
}

extension MainViewController {
    
    // Action viewModelBinding
    private func update(isShown: Bool) {
        
        DispatchQueue.main.async {
            if isShown {
                self.activityIndicator.startAnimating()
            }
            else {
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    private func showAlert(title: String?, subtitle: String?, completion: (() -> Void)? = nil) {
        if title == nil {
            return
        }
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in completion?() }))
            self.present(alert, animated: true)
        }
    }
}

extension MainViewController: UISearchResultsUpdating, UISearchBarDelegate, UITextFieldDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        
        let searchText = (searchController.searchBar.text ?? "")
        viewModel.searchTextSubject.send(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if photoSearchElements.isEmpty {
            return
        }
        let indexPath = IndexPath(row: 0, section: 0)
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
        viewModel.searchTextSubject.send(nil)
    }
}
