import UIKit

final class AppCoordinator: Coordinator {
    
    var navigationController: UINavigationController?
    var childCoordinators: [Coordinator] = []
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func start() {
        showMainCoordinator()
    }
    
    private func showMainCoordinator() {
        let tabBarController = UITabBarController()
        let mainCoordinator = MainCoordinator(tabBarController: tabBarController)
        childCoordinators.append(mainCoordinator)
        mainCoordinator.start()
        navigationController?.pushViewController(tabBarController, animated: true)
    }
}

