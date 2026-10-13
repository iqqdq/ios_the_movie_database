//
//  TableFooterView.swift
//  TheMovieDatabase
//
//  Created by Artur on 13.10.2026.
//

import UIKit

final class TableFooterView: UIView {

    private var onRetryTap: (() -> Void)?

    // MARK: - UI

    private let spinner: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.isHidden = true
        return button
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    convenience init() {
        self.init(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 0,
                height: 60.0
            )
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    /// Показывает спиннер загрузки.
    func showLoading() {
        spinner.startAnimating()
        retryButton.isHidden = true
        onRetryTap = nil
    }

    /// Показывает кнопку повтора с заданным заголовком.
    func showRetry(
        title: String,
        action: @escaping () -> Void
    ) {
        spinner.stopAnimating()
        retryButton.setTitle(title, for: .normal)
        retryButton.isHidden = false
        onRetryTap = action
    }

    func hide() {
        spinner.stopAnimating()
        retryButton.isHidden = true
        onRetryTap = nil
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(spinner)
        addSubview(retryButton)

        retryButton.addAction(
            UIAction { [weak self] _ in
                self?.onRetryTap?()
            },
            for: .touchUpInside
        )
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),

            retryButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
