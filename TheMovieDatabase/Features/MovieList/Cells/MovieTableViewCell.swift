//
//  MovieTableViewCell.swift
//  TheMovieDatabase
//
//  Created by Artur on 02.10.2026.
//

import UIKit

final class MovieTableViewCell: UITableViewCell {

    // MARK: - Identifier

    static let identifier = "MovieTableViewCell"

    // MARK: - UI

    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let posterWidth: CGFloat = 80
        static let posterHeight: CGFloat = 120
        static let spacing: CGFloat = 10

        static var cellHeight: CGFloat {
            posterHeight + verticalPadding * 2
        }
    }

    let separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()

    let posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor(named: "posterColor")
        imageView.layer.cornerRadius = 8.0
        imageView.clipsToBounds = true
        return imageView
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14.0, weight: .medium)
        label.textColor = UIColor(named: "titleColor")
        label.numberOfLines = 2
        return label
    }()

    let releaseDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 10.0, weight: .medium)
        label.textColor = UIColor(named: "releaseColor")
        label.numberOfLines = 1
        return label
    }()

    let overviewLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 10.0)
        label.textColor = UIColor(named: "releaseColor")
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        releaseDateLabel.text = nil
        overviewLabel.text = nil
        posterImageView.image = nil
        separatorView.isHidden = false
    }

    // MARK: - Public API
    
    func configure(with movie: Movie, isLast: Bool) {
        nameLabel.text = movie.title
        releaseDateLabel.text =
            DateHelper.shared.year(from: movie.releaseDate) ?? ""
        overviewLabel.text = movie.overview
        setSeparatorHidden(isLast)

        posterImageView.image = nil
        guard let url = movie.posterURL else { return }

        ImageLoader.shared.load(url: url) { [weak self] image in
            DispatchQueue.main.async {
                self?.posterImageView.image = image
            }
        }
    }

    func setSeparatorHidden(_ hidden: Bool) {
        separatorView.isHidden = hidden
    }

    // MARK: - Setup UI

    private func setupUI() {
        contentView.addSubview(separatorView)
        contentView.addSubview(posterImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(releaseDateLabel)
        contentView.addSubview(overviewLabel)

        NSLayoutConstraint.activate([
            // Separator view
            separatorView.heightAnchor.constraint(equalToConstant: 1.0),
            separatorView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Layout.horizontalPadding
            ),
            separatorView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: 0.0
            ),
            separatorView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: 0.0
            ),

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
            posterImageView.widthAnchor.constraint(
                equalToConstant: Layout.posterWidth
            ),
            posterImageView.heightAnchor.constraint(
                equalToConstant: Layout.posterHeight
            ),

            // Name label
            nameLabel.leadingAnchor.constraint(
                equalTo: posterImageView.trailingAnchor,
                constant: Layout.horizontalPadding
            ),
            nameLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Layout.horizontalPadding
            ),
            nameLabel.topAnchor.constraint(equalTo: posterImageView.topAnchor),

            // Release date label
            releaseDateLabel.leadingAnchor.constraint(
                equalTo: nameLabel.leadingAnchor
            ),
            releaseDateLabel.trailingAnchor.constraint(
                equalTo: nameLabel.trailingAnchor
            ),
            releaseDateLabel.topAnchor.constraint(
                equalTo: nameLabel.bottomAnchor,
                constant: Layout.spacing / 2.0
            ),

            // Description label
            overviewLabel.leadingAnchor.constraint(
                equalTo: nameLabel.leadingAnchor
            ),
            overviewLabel.trailingAnchor.constraint(
                equalTo: nameLabel.trailingAnchor
            ),
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
}
