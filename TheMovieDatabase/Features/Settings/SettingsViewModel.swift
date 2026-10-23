//
//  SettingsViewModel.swift
//  TheMovieDatabase
//
//  Created by Artur on 23.10.2026.
//

import Foundation
import UIKit

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark
}

final class SettingsViewModel {

    // MARK: - Dependencies

    private let repository: SettingsRepositoryProtocol
    private let userDefaults: UserDefaults

    // MARK: - Output

    var onCacheCleared: (() -> Void)?
    var onFavouritesCleared: (() -> Void)?

    private(set) var currentTheme: AppTheme {
        didSet {
            userDefaults.set(currentTheme.rawValue, forKey: "app_theme")
        }
    }

    var isDarkMode: Bool {
        switch currentTheme {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            let window = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }

            return window?.traitCollection.userInterfaceStyle == .dark
        }
    }

    // MARK: - Init

    init(
        repository: SettingsRepositoryProtocol = SettingsRepository(),
        userDefaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.userDefaults = userDefaults

        let savedTheme = userDefaults.string(forKey: "app_theme") ?? ""
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .system
    }

    // MARK: - Public

    func clearCache() {
        repository.clearCache { [weak self] in
            self?.onCacheCleared?()
        }
    }

    func clearFavourites() {
        repository.clearFavourites { [weak self] in
            self?.onFavouritesCleared?()
        }
    }

    func updateTheme(isDarkMode: Bool) {
        currentTheme = isDarkMode ? .dark : .light
    }
}
