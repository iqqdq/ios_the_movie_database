//
//  SettingsViewController.swift
//  TheMovieDatabase
//
//  Created by Artur on 23.10.2026.
//

import UIKit

final class SettingsViewController: UIViewController {

    private let viewModel: SettingsViewModel

    // MARK: - UI

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    private lazy var themeSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.addTarget(self, action: #selector(themeSwitchChanged), for: .valueChanged)
        return toggle
    }()

    // MARK: - Init

    init(viewModel: SettingsViewModel = SettingsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        themeSwitch.isOn = viewModel.isDarkMode
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.onCacheCleared = { [weak self] in
            self?.showSuccessAlert(
                message: NSLocalizedString("cache_cleared", comment: "Cache cleared success message")
            )
        }
        
        viewModel.onFavouritesCleared = { [weak self] in
            self?.showSuccessAlert(
                message: NSLocalizedString("favourites_cleared", comment: "Favourites cleared success message")
            )
        }
    }

    // MARK: - Actions
    
    @objc private func themeSwitchChanged() {
        viewModel.updateTheme(isDarkMode: themeSwitch.isOn)
    }

    private func didTapClearCache() {
        showConfirmationAlert(
            title: NSLocalizedString("clear_cache_title", comment: "Clear cache alert title"),
            message: NSLocalizedString("clear_cache_message", comment: "Clear cache alert message")
        ) { [weak self] in
            self?.viewModel.clearCache()
        }
    }
    
    private func didTapClearFavourites() {
        showConfirmationAlert(
            title: NSLocalizedString("clear_favourites_title", comment: "Clear favourites alert title"),
            message: NSLocalizedString("clear_favourites_message", comment: "Clear favourites alert message")
        ) { [weak self] in
            self?.viewModel.clearFavourites()
        }
    }
    
    private func showConfirmationAlert(title: String, message: String, onConfirm: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("cancel", comment: "Cancel button"),
            style: .cancel
        ))
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("clear", comment: "Clear button"),
            style: .destructive
        ) { _ in
            onConfirm()
        })
        
        present(alert, animated: true)
    }

    private func showSuccessAlert(message: String) {
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("ok", comment: "OK button"),
            style: .default
        ))
        present(alert, animated: true)
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        themeSwitch.isOn = viewModel.isDarkMode
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Внешний вид и Данные
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 2 // Кэш и Избранное
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return NSLocalizedString("appearance_section", comment: "Appearance section")
        case 1: return NSLocalizedString("data_section", comment: "Data section")
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        
        switch indexPath.section {
        case 0:
            content.text = NSLocalizedString("dark_theme", comment: "Dark theme toggle")
            cell.accessoryView = themeSwitch
            cell.selectionStyle = .none
            
        case 1:
            content.textProperties.color = .systemRed
            if indexPath.row == 0 {
                content.text = NSLocalizedString("clear_cache", comment: "Clear cache button")
            } else {
                content.text = NSLocalizedString("clear_favourites", comment: "Clear favourites button")
            }
            
        default:
            break
        }
        
        cell.contentConfiguration = content
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                didTapClearCache()
            } else {
                didTapClearFavourites()
            }
        }
    }
}
