import UIKit
import Combine

final class MainCoordinator: Coordinator {
    var navigationController: UINavigationController?
    var tabBarController: UITabBarController
    
    var childCoordinators: [Coordinator] = []
    private var cancellables: Set<AnyCancellable> = []
    
    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }
    
    func start() {
        showMainViewController()
    }
    
    private func showMainViewController() {
        
        let mainRouting = MainViewModelRouting()
        let mainViewModel = MainViewModelImpl(routing: mainRouting)
        let mainViewController = MainViewController()
        let mainNavController = UINavigationController(rootViewController: mainViewController)
        mainViewController.viewModel = mainViewModel
        
        mainRouting.detailDidTapSubject
            .sink { [weak self] photo in
                self?.showDetailsViewController(photo: photo)
            }.store(in: &cancellables)
        
        let favoritesRouting = FavoritesViewModelRouting()
        let favoritesViewModel = FavoritesViewModelImpl(routing: favoritesRouting)
        let favoritesViewController = FavoritesViewController()
        let favoritesNavController = UINavigationController(rootViewController: favoritesViewController)
        favoritesViewController.viewModel = favoritesViewModel
        
        favoritesRouting.detailDidTapSubject
            .sink { [weak self] photo in
                self?.showDetailsViewController(photo: photo)
            }.store(in: &cancellables)
        
        [mainNavController, favoritesNavController].forEach { $0.navigationBar.prefersLargeTitles = true
            $0.navigationItem.largeTitleDisplayMode = .automatic
        }
        
        mainNavController.tabBarItem = UITabBarItem(title: "Photos", image: UIImage(systemName: "mail.fill"), tag: 1)
        favoritesNavController.tabBarItem = UITabBarItem(title: "Favorites", image: UIImage(systemName: "filemenu.and.selection"), tag: 2)
        
        tabBarController.viewControllers = [mainNavController, favoritesNavController]
    }
    
    private func showDetailsViewController(photo: PhotoElement) {
        let detailRouting = DetailViewModelRouting()
        let detailViewModel = DetailViewModelImpl(routing: detailRouting, photoElement: photo)
        let detailViewController = DetailViewController()
        detailViewController.viewModel = detailViewModel
        tabBarController.navigationController?.pushViewController(detailViewController, animated: true)
    }
}
