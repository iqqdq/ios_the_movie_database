//
//  MovieListViewController.swift
//  TheMovieDatabase
//
//  Created by Artur on 01.10.2026.
//

import UIKit

final class MovieListViewController: UIViewController {

    private let viewModel: MovieListViewModel

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

    // MARK: - Footer

    private let tableFooterView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 60))
        return view
    }()

    private let footerSpinner: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var footerRetryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(
            NSLocalizedString("retry_button", comment: "Кнопка повтора"),
            for: .normal
        )
        button.isHidden = true
        button.addAction(
            UIAction { [weak self] _ in
                self?.viewModel.retryLoadMore()
            },
            for: .touchUpInside
        )
        return button
    }()

    // MARK: - Empty state

    private let emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var emptyStateButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(
            NSLocalizedString("refresh_button", comment: "Кнопка обновления"),
            for: .normal
        )
        button.addAction(
            UIAction { [weak self] _ in
                self?.viewModel.refreshMovies()
            },
            for: .touchUpInside
        )
        return button
    }()

    // MARK: - Init

    init(viewModel: MovieListViewModel = MovieListViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
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
        viewModel.onStateChanged = { [weak self] state in
            self?.render(state)
        }
    }

    // MARK: - Rendering

    private func render(_ state: MovieListViewModel.State) {
        switch state {
        case .idle:
            break

        case .loading, .refreshing:
            activityIndicator.startAnimating()
            footerSpinner.stopAnimating()
            footerRetryButton.isHidden = true
            emptyStateView.isHidden = true

        case .loadingMore:
            footerSpinner.startAnimating()
            footerRetryButton.isHidden = true

        case .loaded:
            activityIndicator.stopAnimating()
            footerSpinner.stopAnimating()
            footerRetryButton.isHidden = true
            emptyStateView.isHidden = true
            
            if refreshControl.isRefreshing {
                refreshControl.endRefreshing()
            }

            let oldCount = tableView.numberOfRows(inSection: 0)
            let newCount = viewModel.movies.count
            if oldCount == 0 || newCount <= oldCount {
                tableView.reloadData()
            } else {
                let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
                tableView.performBatchUpdates {
                    tableView.insertRows(at: indexPaths, with: .none)
                }
            }

        case .empty:
            activityIndicator.stopAnimating()
            footerSpinner.stopAnimating()
            footerRetryButton.isHidden = true
            emptyStateView.isHidden = false
            refreshControl.endRefreshing()
            tableView.reloadData()
            emptyStateLabel.text = NSLocalizedString(
                "nothing_found",
                comment: "Ничего не найдено"
            )

        case .error(let message):
            activityIndicator.stopAnimating()
            footerSpinner.stopAnimating()
            footerRetryButton.isHidden = true
            emptyStateView.isHidden = false
            refreshControl.endRefreshing()
            tableView.reloadData()
            emptyStateLabel.text = String(
                format: NSLocalizedString(
                    "failed_to_load_format",
                    comment: "Ошибка загрузки"
                ),
                message
            )

        case .loadMoreError:
            footerSpinner.stopAnimating()
            footerRetryButton.isHidden = false
            emptyStateView.isHidden = true
            refreshControl.endRefreshing()
        }
    }

    // MARK: - Setup UI

    private func setupUI() {
        setupTableView()
        setupActivityIndicator()
        setupEmptyState()
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

    private func setupTableView() {
        setupFooter()

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

    private func setupFooter() {
        tableFooterView.addSubview(footerSpinner)
        tableFooterView.addSubview(footerRetryButton)

        NSLayoutConstraint.activate([
            footerSpinner.centerXAnchor.constraint(
                equalTo: tableFooterView.centerXAnchor
            ),
            footerSpinner.centerYAnchor.constraint(
                equalTo: tableFooterView.centerYAnchor
            ),

            footerRetryButton.centerXAnchor.constraint(
                equalTo: tableFooterView.centerXAnchor
            ),
            footerRetryButton.centerYAnchor.constraint(
                equalTo: tableFooterView.centerYAnchor
            ),
        ])
    }

    private func setupEmptyState() {
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateView.addSubview(emptyStateButton)

        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            emptyStateView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
            emptyStateView.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor,
                constant: 24
            ),
            emptyStateView.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -24
            ),

            emptyStateLabel.topAnchor.constraint(
                equalTo: emptyStateView.topAnchor
            ),
            emptyStateLabel.leadingAnchor.constraint(
                equalTo: emptyStateView.leadingAnchor
            ),
            emptyStateLabel.trailingAnchor.constraint(
                equalTo: emptyStateView.trailingAnchor
            ),

            emptyStateButton.topAnchor.constraint(
                equalTo: emptyStateLabel.bottomAnchor,
                constant: 16
            ),
            emptyStateButton.centerXAnchor.constraint(
                equalTo: emptyStateView.centerXAnchor
            ),
            emptyStateButton.bottomAnchor.constraint(
                equalTo: emptyStateView.bottomAnchor
            ),
        ])
    }
}

// MARK: - UITableViewDelegate

extension MovieListViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        let movie = viewModel.movies[indexPath.row]
        let movieDetailViewController = MovieDetailViewController(
            movie: movie
        )
        navigationController?.pushViewController(
            movieDetailViewController,
            animated: true
        )
    }
}

// MARK: - UITableViewDataSource

extension MovieListViewController: UITableViewDataSource {
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
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: MovieTableViewCell.identifier,
                for: indexPath
            ) as! MovieTableViewCell
        let movie = viewModel.movies[indexPath.row]
        let isLast = indexPath.row == viewModel.movies.count - 1
        cell.configure(with: movie, isLast: isLast)
        return cell
    }
}

// MARK: - UITableViewDataSourcePrefetching

extension MovieListViewController: UITableViewDataSourcePrefetching {

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
