//
//  DetailViewController.swift
//  TheMovieDatabase
//
//  Created by Artur on 06.10.2026.
//

import Kingfisher
import UIKit

final class DetailViewController: UIViewController {

    private let movie: Movie
    private let viewModel: DetailViewModel

    // MARK: - UI

    enum Layout {
        static let horizontalPadding: CGFloat = 24.0
        static let verticalSpacing: CGFloat = 16.0
        static let posterAspectRatio: CGFloat = 3.0 / 2.0  // height / width
    }

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor(named: "posterColor")
        imageView.layer.cornerRadius = 8.0
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var favouriteBarButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "heart"),
            style: .plain,
            target: self,
            action: #selector(favouriteButtonTapped)
        )
        return button
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20.0, weight: .medium)
        label.textColor = UIColor(named: "titleColor")
        label.numberOfLines = 0
        return label
    }()

    private let releaseDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20.0, weight: .medium)
        label.textColor = UIColor(named: "releaseColor")
        label.numberOfLines = 1
        return label
    }()

    private let overviewLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16.0)
        label.textColor = UIColor(named: "releaseColor")
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

    init(movie: Movie) {
        self.movie = movie
        self.viewModel = DetailViewModel(movie: movie)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupScrollView()
        setupSubviews()
        configure(with: movie)
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.onFavouriteStatusChanged = { [weak self] isFavourite in
            self?.updateFavouriteIcon(isFavourite: isFavourite)
        }
    }

    @objc private func favouriteButtonTapped() {
        viewModel.toggleFavourite()
    }

    // MARK: - Setup UI

    private func setupNavigationBar() {
        let transparent = UINavigationBarAppearance()
        transparent.configureWithTransparentBackground()

        let blur = UINavigationBarAppearance()
        blur.configureWithDefaultBackground()

        navigationItem.scrollEdgeAppearance = transparent
        navigationItem.standardAppearance = blur
        navigationItem.compactAppearance = blur
        navigationItem.rightBarButtonItem = favouriteBarButton
        
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupScrollView() {
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupSubviews() {
        scrollView.addSubview(posterImageView)
        scrollView.addSubview(nameLabel)
        scrollView.addSubview(releaseDateLabel)
        scrollView.addSubview(overviewLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        let contentGuide = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide

        NSLayoutConstraint.activate([
            contentGuide.widthAnchor.constraint(
                equalTo: frameGuide.widthAnchor
            ),

            // Poster
            posterImageView.topAnchor.constraint(
                equalTo: contentGuide.topAnchor
            ),
            posterImageView.leadingAnchor.constraint(
                equalTo: contentGuide.leadingAnchor,
                constant: Layout.horizontalPadding
            ),
            posterImageView.trailingAnchor.constraint(
                equalTo: contentGuide.trailingAnchor,
                constant: -Layout.horizontalPadding
            ),
            posterImageView.heightAnchor.constraint(
                equalTo: posterImageView.widthAnchor,
                multiplier: Layout.posterAspectRatio
            ),

            // Name
            nameLabel.leadingAnchor.constraint(
                equalTo: contentGuide.leadingAnchor,
                constant: Layout.horizontalPadding
            ),
            nameLabel.trailingAnchor.constraint(
                equalTo: contentGuide.trailingAnchor,
                constant: -Layout.horizontalPadding
            ),
            nameLabel.topAnchor.constraint(
                equalTo: posterImageView.bottomAnchor,
                constant: Layout.verticalSpacing
            ),

            // Release date
            releaseDateLabel.leadingAnchor.constraint(
                equalTo: nameLabel.leadingAnchor
            ),
            releaseDateLabel.trailingAnchor.constraint(
                equalTo: nameLabel.trailingAnchor
            ),
            releaseDateLabel.topAnchor.constraint(
                equalTo: nameLabel.bottomAnchor,
                constant: Layout.verticalSpacing
            ),

            // Overview
            overviewLabel.leadingAnchor.constraint(
                equalTo: nameLabel.leadingAnchor
            ),
            overviewLabel.trailingAnchor.constraint(
                equalTo: nameLabel.trailingAnchor
            ),
            overviewLabel.topAnchor.constraint(
                equalTo: releaseDateLabel.bottomAnchor,
                constant: Layout.verticalSpacing
            ),
            overviewLabel.bottomAnchor.constraint(
                equalTo: contentGuide.bottomAnchor,
                constant: -Layout.verticalSpacing
            ),
        ])
    }

    // MARK: - Configuration

    private func configure(with movie: Movie) {
        nameLabel.text = movie.title
        releaseDateLabel.text = movie.releaseDate.year
        overviewLabel.text = movie.overview

        if let url = movie.posterURL {
            posterImageView.kf.setImage(
                with: url,
                options: [.transition(.fade(0.2))]
            )
        }
    }

    private func updateFavouriteIcon(isFavourite: Bool) {
        let iconName = isFavourite ? "heart.fill" : "heart"
        let color = isFavourite ? UIColor.systemRed : UIColor.white
        favouriteBarButton.image = UIImage(systemName: iconName)
        favouriteBarButton.tintColor = color
    }
}
