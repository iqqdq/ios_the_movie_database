//
//  MovieDetailViewController.swift
//  TheMovieDatabase
//
//  Created by Artur on 06.10.2026.
//

import UIKit

final class MovieDetailViewController: UIViewController {

    private let movie: Movie
    private let posterImage: UIImage

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    let posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor(named: "posterColor")
        imageView.clipsToBounds = true
        return imageView
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20.0, weight: .medium)
        label.textColor = UIColor(named: "titleColor")
        label.numberOfLines = 0
        return label
    }()

    let releaseDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20.0, weight: .medium)
        label.textColor = UIColor(named: "releaseColor")
        label.numberOfLines = 1
        return label
    }()

    let overviewLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16.0)
        label.textColor = UIColor(named: "releaseColor")
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

    init(movie: Movie, posterImage: UIImage) {
        self.movie = movie
        self.posterImage = posterImage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false
    }

    override func viewDidLoad() {
        setupScrollView()
        setupUI()
    }

    // MARK: - Setup UI

    private func setupScrollView() {
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupUI() {
        scrollView.addSubview(posterImageView)
        scrollView.addSubview(nameLabel)
        scrollView.addSubview(releaseDateLabel)
        scrollView.addSubview(overviewLabel)

        posterImageView.image = posterImage
        nameLabel.text = movie.title
        releaseDateLabel.text = DateHelper.shared.year(from: movie.releaseDate)
        overviewLabel.text = movie.overview

        let contentGuide = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide
        let posterAspectRatio = posterImage.size.width / posterImage.size.height

        NSLayoutConstraint.activate([
            contentGuide.widthAnchor.constraint(equalTo: frameGuide.widthAnchor),

            // Poster
            posterImageView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor, constant: 24.0),
            posterImageView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor, constant: -24.0),
            posterImageView.heightAnchor.constraint(
                equalTo: posterImageView.widthAnchor,
                multiplier: 1.0 / posterAspectRatio
            ),

            // Name
            nameLabel.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor, constant: 24.0),
            nameLabel.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor, constant: -24.0),
            nameLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 16.0),

            // Release date
            releaseDateLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            releaseDateLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            releaseDateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 12.0),

            // Overview
            overviewLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            overviewLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            overviewLabel.topAnchor.constraint(equalTo: releaseDateLabel.bottomAnchor, constant: 16.0),

            // Низ контента → задаёт contentSize.height → вертикальный скролл
            overviewLabel.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor, constant: -24.0),
        ])
    }
}
