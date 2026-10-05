//
//  MovieListViewController.swift
//  TheMovieDatabase
//
//  Created by Artur on 01.10.2026.
//

import UIKit

class MovieListViewController: UIViewController {

    private let viewModel: MovieListViewModel

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.fetchMovies()
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.onMoviesUpdated = { [weak self] in
            self?.tableView.reloadData()
        }

        viewModel.onLoadingChanged = { [weak self] isLoading in
            if isLoading {
                self?.activityIndicator.startAnimating()
            } else {
                self?.activityIndicator.stopAnimating()
            }
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
        navigationController?.isNavigationBarHidden = true
        view.backgroundColor = .systemBackground
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
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        //        let movie = viewModel.movies[indexPath.row]
        //        let detailVC = MovieDetailViewController(movie: movie)
        //        navigationController?.pushViewController(detailVC, animated: true)
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
