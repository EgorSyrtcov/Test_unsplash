import UIKit
import Combine

final class FavoritesViewController: UIViewController {
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.registerClassForCell(FavoritesCell.self)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 120
        return tableView
    }()
    
    // MARK: Private
    private var cancellables: Set<AnyCancellable> = []
    private var photoElements = [PhotoElement]()
    
    // MARK: Public
    var viewModel: FavoritesViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupUI()
        viewModelBinding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.updateStorageServiceSubject.send()
    }
    
    private func setup() {
        title = "Favorites"
        view.backgroundColor = .white
    }
    
    private func viewModelBinding() {
        viewModel.updateStorageServicePublisher
            .sink { [weak self] returnValue in
                guard let self = self else { return }
                self.photoElements = returnValue
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    private func setupUI() {
        view.addSubviews(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}

extension FavoritesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photoElements.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: FavoritesCell = tableView.dequeueReusableCell(for: indexPath)
        let photoElement = photoElements[indexPath.row]
        cell.setup(photoElement)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.deleteStorageServiceSubject.send(photoElements[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.detailCellDidTapSubject.send(photoElements[indexPath.row])
    }
}
