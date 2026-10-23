//
//  PopularViewController.swift
//  TheMovieDatabase
//
//  Created by Artur on 01.10.2026.
//

import UIKit

final class PopularViewController: UIViewController {

    private let viewModel: PopularViewModel

    var onMovieSelected: ((Movie) -> Void)?

    // MARK: - UI

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addAction(
            UIAction { [weak self] _ in
                self?.viewModel.refreshMovies()
            },
            for: .valueChanged
        )
        return control
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

    private let tableFooterView = TableFooterView()
    private let emptyStateView = EmptyStateView()

    // MARK: - Init

    init(viewModel: PopularViewModel = PopularViewModel()) {
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
        viewModel.fetchMovies()
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.onFavouritesChanged = { [weak self] in
            self?.tableView.reloadData()
        }

        viewModel.onStateChanged = { [weak self] state in
            self?.updateState(state)
        }
    }

    // MARK: - State

    private func updateState(_ state: PopularState) {
        switch state {
        case .idle:
            break
        case .loading, .refreshing:
            renderLoading()
        case .loadingMore:
            renderLoadingMore()
        case .loaded:
            renderLoaded()
        case .empty:
            renderEmpty()
        case .error(let error):
            renderError(error)
        case .loadMoreError:
            renderLoadMoreError()
        }
    }

    private func renderLoading() {
        activityIndicator.startAnimating()
        tableFooterView.hide()
        emptyStateView.hide()
    }

    private func renderLoadingMore() {
        tableFooterView.showLoading()
    }

    private func renderLoaded() {
        activityIndicator.stopAnimating()
        tableFooterView.hide()
        emptyStateView.hide()

        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }

        let oldCount = tableView.numberOfRows(inSection: 0)
        let newCount = viewModel.movies.count

        if oldCount == 0 || newCount <= oldCount {
            tableView.reloadData()
        } else {
            let indexPaths = (oldCount..<newCount).map {
                IndexPath(row: $0, section: 0)
            }
            tableView.performBatchUpdates {
                tableView.insertRows(at: indexPaths, with: .none)
            }
        }
    }

    private func renderEmpty() {
        activityIndicator.stopAnimating()
        tableFooterView.hide()
        refreshControl.endRefreshing()
        tableView.reloadData()

        emptyStateView.show(
            title: NSLocalizedString(
                "nothing_found",
                comment: "Empty state title on the popular screen"
            ),
            buttonTitle: NSLocalizedString(
                "refresh_button",
                comment:
                    "Button to refresh the popular after an empty result"
            ),
            action: { [weak self] in
                self?.viewModel.refreshMovies()
            }
        )
    }

    private func renderError(_ message: String) {
        activityIndicator.stopAnimating()
        tableFooterView.hide()
        refreshControl.endRefreshing()
        tableView.reloadData()

        emptyStateView.show(
            title: String(
                format: NSLocalizedString(
                    "failed_to_load_format",
                    comment: "Error state title on the popular screen"
                ),
                message
            ),
            buttonTitle: NSLocalizedString(
                "refresh_button",
                comment:
                    "Button to refresh the popular after a load error"
            ),
            action: { [weak self] in
                self?.viewModel.refreshMovies()
            }
        )
    }

    private func renderLoadMoreError() {
        emptyStateView.hide()
        refreshControl.endRefreshing()

        tableFooterView.showRetry(
            title: NSLocalizedString(
                "retry_button",
                comment:
                    "Button to retry loading more movies at the bottom of the list"
            ),
            action: { [weak self] in
                self?.viewModel.retryLoadMore()
            }
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
        tableView.prefetchDataSource = self
        tableView.refreshControl = refreshControl
        tableView.tableFooterView = tableFooterView

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

extension PopularViewController: UITableViewDelegate {
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

extension PopularViewController: UITableViewDataSource {
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
        let isFavourite = viewModel.isFavourite(movie.id)

        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: MovieTableViewCell.identifier,
                for: indexPath
            ) as! MovieTableViewCell
        cell.configure(with: movie, isLast: isLast, isFavourite: isFavourite)
        cell.onFavouriteTapped = { [weak self] in
            self?.viewModel.toggleFavourite(movie: movie)
        }

        return cell
    }
}

// MARK: - UITableViewDataSourcePrefetching

extension PopularViewController: UITableViewDataSourcePrefetching {
    func tableView(
        _ tableView: UITableView,
        prefetchRowsAt indexPaths: [IndexPath]
    ) {
        guard let maxRow = indexPaths.map({ $0.row }).max() else { return }
        let threshold = 5
        if maxRow >= viewModel.movies.count - threshold {
            viewModel.fetchMovies()
        }
    }
}
