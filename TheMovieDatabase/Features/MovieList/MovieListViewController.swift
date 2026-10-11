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

    private let tableFooterView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.frame = CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0)
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
        return tableView
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
        viewModel.onLoadingChanged = { [weak self] isLoading in
            if isLoading {
                self?.activityIndicator.startAnimating()
            } else {
                self?.activityIndicator.stopAnimating()
            }
        }

        viewModel.onLoadingMoreChanged = { [weak self] isLoading in
            if isLoading {
                self?.tableFooterView.startAnimating()
            } else {
                self?.tableFooterView.stopAnimating()
            }
        }

        viewModel.onMoviesUpdated = { [weak self] in
            self?.tableView.reloadData()
        }

        viewModel.onRefreshFinished = { [weak self] in
            self?.refreshControl.endRefreshing()
        }

        viewModel.onError = { [weak self] error in
            let alert = UIAlertController(
                title: nil,
                message: error.errorDescription,
                preferredStyle: .alert
            )
            let action = UIAlertAction(title: "OK", style: .default)
            alert.addAction(action)
            self?.present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - Setup UI

    private func setupUI() {
        setupTableView()
        setupActivityIndicator()
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
        tableView.delegate = self
        tableView.dataSource = self
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
}

// MARK: - UITableViewDelegate

extension MovieListViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height
        let threshold: CGFloat = 200

        guard contentHeight > 0 else { return }

        if offsetY > contentHeight - frameHeight - threshold {
            viewModel.fetchMovies()
        }
    }

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
