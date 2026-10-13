//
//  EmptyStateView.swift
//  TheMovieDatabase
//
//  Created by Artur on 13.10.2026.
//

import UIKit

final class EmptyStateView: UIView {

    private var onActionTap: (() -> Void)?

    // MARK: - UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    /// Cостояние с заголовком и кнопкой действия.
    func show(
        title: String,
        buttonTitle: String,
        action: @escaping () -> Void
    ) {
        titleLabel.text = title
        actionButton.setTitle(buttonTitle, for: .normal)
        actionButton.isHidden = false
        onActionTap = action
        isHidden = false
    }

    /// Cостояние только с заголовком.
    func show(title: String) {
        titleLabel.text = title
        actionButton.setTitle(nil, for: .normal)
        actionButton.isHidden = true
        onActionTap = nil
        isHidden = false
    }
    
    func hide() {
        isHidden = true
    }

    // MARK: - Setup UI

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        isHidden = true

        addSubview(titleLabel)
        addSubview(actionButton)

        actionButton.addAction(
            UIAction { [weak self] _ in
                self?.onActionTap?()
            },
            for: .touchUpInside
        )
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            actionButton.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 16
            ),
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
