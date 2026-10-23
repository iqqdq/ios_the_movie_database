//
//  FavouritesViewController.swift
//  TheMovieDatabase
//
//  Created by Artur on 23.10.2026.
//

import UIKit

final class FavouritesViewController: UIViewController {

    private let viewModel: FavouritesViewModel

    var onMovieSelected: ((Movie) -> Void)?

    // MARK: - UI

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(
            MovieTableViewCell.self,
            forCellReuseIdentifier: MovieTableViewCell.identifier
        )
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = true
        return tableView
    }()

    private let emptyStateView = EmptyStateView()

    // MARK: - Init

    init(viewModel: FavouritesViewModel = FavouritesViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        setupUI()
        bindViewModel()
        viewModel.fetchFavourites()
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] state in
            self?.updateState(state)
        }
    }

    // MARK: - State

    private func updateState(_ state: FavouritesState) {
        switch state {
        case .idle:
            break
        case .loading:
            renderLoading()
        case .loaded:
            renderLoaded()
        case .empty:
            renderEmpty()
        }
    }

    private func renderLoading() {
        activityIndicator.startAnimating()
        emptyStateView.hide()
    }

    private func renderLoaded() {
        activityIndicator.stopAnimating()
        emptyStateView.hide()
        tableView.reloadData()
    }

    private func renderEmpty() {
        activityIndicator.stopAnimating()
        tableView.reloadData()

        emptyStateView.show(
            title: NSLocalizedString(
                "no_favourites_found",
                comment: "Empty state title on the favourites screen"
            )
        )
    }

    // MARK: - Setup UI

    private func setupUI() {
        setupTableView()
        setupActivityIndicator()
        setupEmptyState()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            activityIndicator.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
        ])
    }

    private func setupEmptyState() {
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            emptyStateView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
            emptyStateView.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor,
                constant: 24.0
            ),
            emptyStateView.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -24.0
            ),
        ])
    }
}

// MARK: - UITableViewDelegate

extension FavouritesViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        let movie = viewModel.movies[indexPath.row]
        onMovieSelected?(movie)
    }
}

// MARK: - UITableViewDataSource

extension FavouritesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        viewModel.movies.count
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        MovieTableViewCell.Layout.cellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let movie = viewModel.movies[indexPath.row]
        let isLast = indexPath.row == viewModel.movies.count - 1

        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: MovieTableViewCell.identifier,
                for: indexPath
            ) as! MovieTableViewCell
        cell.configure(with: movie, isLast: isLast, isFavourite: true)
        cell.onFavouriteTapped = { [weak self] in
            self?.viewModel.removeFavourite(movie: movie)
        }

        return cell
    }
}
