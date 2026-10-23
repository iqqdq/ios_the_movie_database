//
//  Coordinator.swift
//  TheMovieDatabase
//
//  Created by Artur on 13.10.2026.
//

import UIKit

// MARK: - Coordinator

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }

    func start()
}

// MARK: - AppCoordinator

final class AppCoordinator: Coordinator {

    // MARK: - Coordinator

    var childCoordinators: [Coordinator] = []

    // MARK: - Dependencies

    private let window: UIWindow
    private let repository: MovieRepositoryProtocol

    // MARK: - Navigation

    private let tabBarController = MainTabBarController()

    private let popularNavigation = UINavigationController()
    private let searchNavigation = UINavigationController()
    private let favoritesNavigation = UINavigationController()
    private let settingsNavigation = UINavigationController()

    // MARK: - Init

    init(
        window: UIWindow,
        repository: MovieRepositoryProtocol = MovieRepository()
    ) {
        self.window = window
        self.repository = repository
    }

    // MARK: - Start

    func start() {
        setupTabBarController()
        setupPopularTab()
        setupSearchTab()
        setupFavoritesTab()
        setupSettingsTab()

        tabBarController.viewControllers = [
            popularNavigation,
            searchNavigation,
            favoritesNavigation,
            settingsNavigation,
        ]

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }

    // MARK: - Tab Bar

    private func setupTabBarController() {
        tabBarController.coordinator = self
    }

    // MARK: - Popular Tab

    private func setupPopularTab() {
        let viewModel = PopularViewModel(repository: repository)

        let viewController = PopularViewController(viewModel: viewModel)
        viewController.onMovieSelected = { [weak self] movie in
            guard let self else { return }
            showDetail(popularNavigation, movie)
        }

        popularNavigation.setNavigationBarHidden(true, animated: false)
        popularNavigation.setViewControllers([viewController], animated: false)
        popularNavigation.tabBarItem = UITabBarItem(
            title: NSLocalizedString(
                "tab_popular",
                comment: "Tab bar title for the popular movies screen"
            ),
            image: UIImage(systemName: "film"),
            selectedImage: UIImage(systemName: "film.fill")
        )
    }

    private func showDetail(
        _ navigationController: UINavigationController,
        _ movie: Movie
    ) {
        let viewController = DetailViewController(movie: movie)
        navigationController.pushViewController(viewController, animated: true)
    }

    // MARK: - Search Tab

    private func setupSearchTab() {
        let viewModel = SearchViewModel(repository: repository)

        let viewController = SearchViewController(viewModel: viewModel)
        viewController.onMovieSelected = { [weak self] movie in
            guard let self else { return }
            showDetail(searchNavigation, movie)
        }

        searchNavigation.setNavigationBarHidden(true, animated: false)
        searchNavigation.setViewControllers([viewController], animated: false)
        searchNavigation.tabBarItem = UITabBarItem(
            title: NSLocalizedString(
                "tab_search",
                comment: "Tab bar title for the search screen"
            ),
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "magnifyingglass")
        )
    }

    // MARK: - Favorites Tab

    private func setupFavoritesTab() {
        let viewController = FavouritesViewController()
        viewController.onMovieSelected = { [weak self] movie in
            guard let self else { return }
            showDetail(favoritesNavigation, movie)
        }
        
        favoritesNavigation.setNavigationBarHidden(true, animated: false)
        favoritesNavigation.setViewControllers(
            [viewController],
            animated: false
        )
        favoritesNavigation.tabBarItem = UITabBarItem(
            title: NSLocalizedString(
                "tab_favorites",
                comment: "Tab bar title for the favorites screen"
            ),
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )
    }

    // MARK: - Settings Tab

    private func setupSettingsTab() {
        let viewController = SettingsViewController()
        settingsNavigation.setNavigationBarHidden(true, animated: false)
        settingsNavigation.setViewControllers([viewController], animated: false)
        settingsNavigation.tabBarItem = UITabBarItem(
            title: NSLocalizedString(
                "tab_settings",
                comment: "Tab bar title for the settings screen"
            ),
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
    }
}
