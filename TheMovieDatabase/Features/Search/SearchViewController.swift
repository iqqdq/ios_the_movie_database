//
//  SearchViewController.swift
//  TheMovieDatabase
//
//  Created by Artur on 14.10.2026.
//

import UIKit

final class SearchViewController: UIViewController {

    private let viewModel: SearchViewModel

    var onMovieSelected: ((Movie) -> Void)?

    // MARK: - Layout

    private enum Layout {
        static let horizontalPadding: CGFloat = 16.0
        static let verticalSpacing: CGFloat = 12.0
        static let textFieldHeight: CGFloat = 44.0
    }

    // MARK: - UI

    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.returnKeyType = .done
        textField.clearButtonMode = .whileEditing
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.placeholder = NSLocalizedString(
            "search_placeholder",
            comment: "Placeholder for search text field"
        )
        textField.addTarget(
            self,
            action: #selector(textFieldDidChange),
            for: .editingChanged
        )
        textField.addTarget(
            self,
            action: #selector(textFieldDidEndOnExit),
            for: .editingDidEndOnExit
        )
        return textField
    }()

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

    private let tableFooterView = TableFooterView()
    private let emptyStateView = EmptyStateView()

    // MARK: - Init

    init(viewModel: SearchViewModel = SearchViewModel()) {
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
        updateState(viewModel.state)
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

    @objc private func textFieldDidChange() {
        viewModel.searchMovie(query: textField.text ?? "")
    }

    @objc private func textFieldDidEndOnExit() {
        textField.resignFirstResponder()
    }

    // MARK: - State

    private func updateState(_ state: SearchState) {
        switch state {
        case .idle:
            renderIdle()
        case .searching:
            renderSearching()
        case .loadingMore:
            renderLoadingMore()
        case .results:
            renderLoaded()
        case .empty:
            renderEmpty()
        case .error(let error):
            renderError(error)
        case .loadMoreError:
            renderLoadMoreError()
        }
    }

    private func renderIdle() {
        activityIndicator.stopAnimating()
        tableView.isHidden = true
        tableFooterView.hide()
        emptyStateView.show(
            title: NSLocalizedString(
                "start_typing",
                comment: "Hint to start typing a search query"
            )
        )
    }

    private func renderSearching() {
        activityIndicator.startAnimating()
        tableView.isHidden = true
        tableFooterView.hide()
        emptyStateView.hide()
    }

    private func renderLoadingMore() {
        tableFooterView.showLoading()
    }

    private func renderLoaded() {
        activityIndicator.stopAnimating()
        tableView.isHidden = false
        tableFooterView.hide()
        emptyStateView.hide()

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
        tableView.isHidden = true
        tableView.reloadData()
        tableFooterView.hide()

        emptyStateView.show(
            title: NSLocalizedString(
                "nothing_found",
                comment: "Empty state title on the search screen"
            )
        )
    }

    private func renderError(_ message: String) {
        activityIndicator.stopAnimating()
        tableView.isHidden = true
        tableView.reloadData()
        tableFooterView.hide()

        emptyStateView.show(
            title: String(
                format: NSLocalizedString(
                    "failed_to_load_format",
                    comment: "Error state title on the search screen"
                ),
                message
            ),
            buttonTitle: NSLocalizedString(
                "refresh_button",
                comment:
                    "Button to refresh the search after a load error"
            ),
            action: { [weak self] in
                guard let self else { return }
                self.viewModel.searchMovie(query: self.textField.text ?? "")
            }
        )
    }

    private func renderLoadMoreError() {
        emptyStateView.hide()

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
        setupTextField()
        setupTableView()
        setupActivityIndicator()
        setupEmptyState()
    }

    private func setupTextField() {
        view.addSubview(textField)

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: Layout.verticalSpacing
            ),
            textField.leftAnchor.constraint(
                equalTo: view.leftAnchor,
                constant: Layout.horizontalPadding
            ),
            textField.rightAnchor.constraint(
                equalTo: view.rightAnchor,
                constant: -Layout.horizontalPadding
            ),
            textField.heightAnchor.constraint(
                equalToConstant: Layout.textFieldHeight
            ),
        ])
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        tableView.tableFooterView = tableFooterView
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(
                equalTo: textField.bottomAnchor,
                constant: Layout.verticalSpacing
            ),
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
                constant: Layout.horizontalPadding
            ),
            emptyStateView.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -Layout.horizontalPadding
            ),
        ])
    }
}

// MARK: - UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
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

extension SearchViewController: UITableViewDataSource {
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

extension SearchViewController: UITableViewDataSourcePrefetching {
    func tableView(
        _ tableView: UITableView,
        prefetchRowsAt indexPaths: [IndexPath]
    ) {
        guard let maxRow = indexPaths.map({ $0.row }).max() else { return }
        let threshold = 5
        if maxRow >= viewModel.movies.count - threshold {
            viewModel.loadMore()
        }
    }
}
