//
//  MovieTableViewCell.swift
//  TheMovieDatabase
//
//  Created by Artur on 02.10.2026.
//

import Kingfisher
import UIKit

final class MovieTableViewCell: UITableViewCell {

    // MARK: - Identifier

    static let identifier = "MovieTableViewCell"

    var onFavouriteTapped: (() -> Void)?

    // MARK: - Layout

    enum Layout {
        static let horizontalPadding: CGFloat = 16.0
        static let verticalPadding: CGFloat = 12.0
        static let posterWidth: CGFloat = 80.0
        static let posterHeight: CGFloat = 120.0
        static let spacing: CGFloat = 10.0
        static let separatorHeight: CGFloat = 1.0
        static let favouriteButtonSize: CGFloat = 28.0

        static var cellHeight: CGFloat {
            posterHeight + verticalPadding * 2.0
        }
    }

    // MARK: - UI

    private let separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
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

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14.0, weight: .medium)
        label.textColor = UIColor(named: "titleColor")
        label.numberOfLines = 2
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let releaseDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 10.0, weight: .medium)
        label.textColor = UIColor(named: "releaseColor")
        label.numberOfLines = 1
        return label
    }()

    private let overviewLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 10.0)
        label.textColor = UIColor(named: "releaseColor")
        label.numberOfLines = 0
        return label
    }()

    private let favouriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowRadius = 2.0
        button.layer.shadowOpacity = 0.5
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        return button
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()

        favouriteButton.addAction(
            UIAction { [weak self] _ in
                self?.onFavouriteTapped?()
            },
            for: .touchUpInside
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.kf.cancelDownloadTask()
        posterImageView.image = nil
        nameLabel.text = nil
        releaseDateLabel.text = nil
        overviewLabel.text = nil
        separatorView.isHidden = false
    }

    // MARK: - Public

    func configure(with movie: Movie, isLast: Bool, isFavourite: Bool) {
        // Poster image
        posterImageView.image = nil
        if let url = movie.posterURL {
            posterImageView.kf.setImage(
                with: url,
                options: [.transition(.fade(0.2))]
            )
        }

        // Text content
        nameLabel.text = movie.title
        releaseDateLabel.text = movie.releaseDate.year
        overviewLabel.text = movie.overview

        // Separator
        setSeparatorHidden(isLast)

        // Like Button
        updateFavouriteIcon(isFavourite: isFavourite)
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(separatorView)
        contentView.addSubview(posterImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(releaseDateLabel)
        contentView.addSubview(overviewLabel)
        contentView.addSubview(favouriteButton)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Separator view
            separatorView.heightAnchor.constraint(equalToConstant: Layout.separatorHeight),
            separatorView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Layout.horizontalPadding
            ),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Poster image
            posterImageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Layout.horizontalPadding
            ),
            posterImageView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: Layout.verticalPadding
            ),
            posterImageView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -Layout.verticalPadding
            ),
            posterImageView.widthAnchor.constraint(equalToConstant: Layout.posterWidth),
            posterImageView.heightAnchor.constraint(equalToConstant: Layout.posterHeight),

            // Name label
            nameLabel.leadingAnchor.constraint(
                equalTo: posterImageView.trailingAnchor,
                constant: Layout.horizontalPadding
            ),
            nameLabel.trailingAnchor.constraint(
                equalTo: favouriteButton.leadingAnchor,
                constant: -Layout.spacing
            ),
            nameLabel.topAnchor.constraint(equalTo: posterImageView.topAnchor),

            // Favourite button
            favouriteButton.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Layout.horizontalPadding
            ),
            favouriteButton.topAnchor.constraint(equalTo: posterImageView.topAnchor),
            favouriteButton.widthAnchor.constraint(equalToConstant: Layout.favouriteButtonSize),
            favouriteButton.heightAnchor.constraint(equalToConstant: Layout.favouriteButtonSize),

            // Release date label
            releaseDateLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            releaseDateLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            releaseDateLabel.topAnchor.constraint(
                equalTo: nameLabel.bottomAnchor,
                constant: Layout.spacing / 2.0
            ),

            // Description label
            overviewLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            overviewLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            overviewLabel.topAnchor.constraint(
                equalTo: releaseDateLabel.bottomAnchor,
                constant: Layout.spacing
            ),
            overviewLabel.bottomAnchor.constraint(
                lessThanOrEqualTo: posterImageView.bottomAnchor,
                constant: 0.0
            ),
        ])
    }

    // MARK: - Helpers

    private func setSeparatorHidden(_ hidden: Bool) {
        separatorView.isHidden = hidden
    }

    private func updateFavouriteIcon(isFavourite: Bool) {
        let iconName = isFavourite ? "heart.fill" : "heart"
        let color = isFavourite ? UIColor.systemRed : UIColor.secondaryLabel
        let image = UIImage(systemName: iconName)
        favouriteButton.setImage(image, for: .normal)
        favouriteButton.tintColor = color
    }
}
